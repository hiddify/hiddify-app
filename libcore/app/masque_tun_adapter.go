package app

import (
	"context"
	"log/slog"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/bepass-org/vwarp/masque"
	"github.com/bepass-org/vwarp/wireguard/tun"
)

// netstackTunAdapter wraps a tun.Device to provide packet forwarding interface
type netstackTunAdapter struct {
	dev             tun.Device
	tunnelBufPool   *sync.Pool
	tunnelSizesPool *sync.Pool
}

func (n *netstackTunAdapter) ReadPacket(buf []byte) (int, error) {
	packetBufsPtr := n.tunnelBufPool.Get().(*[][]byte)
	sizesPtr := n.tunnelSizesPool.Get().(*[]int)

	defer func() {
		(*packetBufsPtr)[0] = nil
		n.tunnelBufPool.Put(packetBufsPtr)
		n.tunnelSizesPool.Put(sizesPtr)
	}()

	(*packetBufsPtr)[0] = buf
	(*sizesPtr)[0] = 0

	_, err := n.dev.Read(*packetBufsPtr, *sizesPtr, 0)
	if err != nil {
		return 0, err
	}

	return (*sizesPtr)[0], nil
}

func (n *netstackTunAdapter) WritePacket(pkt []byte) error {
	_, err := n.dev.Write([][]byte{pkt}, 0)
	return err
}

// isConnectionError checks if the error indicates a closed or broken connection
func isConnectionError(err error) bool {
	if err == nil {
		return false
	}
	errStr := err.Error()
	return strings.Contains(errStr, "use of closed network connection") ||
		strings.Contains(errStr, "connection reset by peer") ||
		strings.Contains(errStr, "broken pipe") ||
		strings.Contains(errStr, "network is unreachable")
}

// AdapterFactory is a function that creates a new MASQUE adapter
type AdapterFactory func() (*masque.MasqueAdapter, error)

// maintainMasqueTunnel continuously forwards packets between the TUN device and MASQUE
// with automatic reconnection on connection failures
func maintainMasqueTunnel(ctx context.Context, l *slog.Logger, adapter *masque.MasqueAdapter, factory AdapterFactory, device *netstackTunAdapter, mtu int) {
	l.Info("Starting MASQUE tunnel packet forwarding with auto-reconnect")

	// Connection state management
	connectionDown := make(chan bool, 1)

	// Track connection state
	var connectionBroken atomic.Bool

	// Forward packets from netstack to MASQUE
	go func() {
		buf := make([]byte, mtu)
		packetCount := 0
		for ctx.Err() == nil {
			// Wait if connection is broken
			if connectionBroken.Load() {
				time.Sleep(100 * time.Millisecond)
				continue
			}

			n, err := device.ReadPacket(buf)
			if err != nil {
				if ctx.Err() != nil {
					return
				}
				l.Error("error reading from TUN device", "error", err)
				continue
			}

			packetCount++
			if packetCount <= 5 || packetCount%100 == 0 {
				l.Debug("TX netstack→MASQUE", "packet", packetCount, "bytes", n)
			}

			// Write packet to MASQUE and handle ICMP response
			icmp, err := adapter.WriteWithICMP(buf[:n])
			if err != nil {
				if isConnectionError(err) {
					if !connectionBroken.Load() {
						l.Warn("MASQUE connection error detected on write", "error", err)
						connectionBroken.Store(true)
						// Signal connection down (non-blocking)
						select {
						case connectionDown <- true:
						default:
						}
					}
				} else {
					l.Error("error writing to MASQUE", "error", err, "packet_size", n)
				}
				continue
			}

			// Handle ICMP response if present
			if len(icmp) > 0 {
				l.Debug("received ICMP response", "size", len(icmp))
				if err := device.WritePacket(icmp); err != nil {
					l.Error("error writing ICMP to TUN device", "error", err)
				}
			}
		}
	}()

	// Forward packets from MASQUE to netstack with connection monitoring
	go func() {
		buf := make([]byte, mtu)
		packetCount := 0
		consecutiveErrors := 0

		for ctx.Err() == nil {
			// Wait if connection is broken
			if connectionBroken.Load() {
				time.Sleep(100 * time.Millisecond)
				continue
			}

			n, err := adapter.Read(buf)
			if err != nil {
				if ctx.Err() != nil {
					return
				}

				if isConnectionError(err) {
					consecutiveErrors++
					if consecutiveErrors == 1 && !connectionBroken.Load() {
						l.Warn("MASQUE connection error detected on read", "error", err)
						connectionBroken.Store(true)
						// Signal connection down (non-blocking)
						select {
						case connectionDown <- true:
						default:
						}
					}
					// Avoid tight error loop
					time.Sleep(500 * time.Millisecond)
				} else {
					l.Error("error reading from MASQUE", "error", err)
					consecutiveErrors++
					if consecutiveErrors > 10 {
						time.Sleep(100 * time.Millisecond)
					}
				}
				continue
			}

			// Reset error counter on successful read
			consecutiveErrors = 0

			packetCount++
			if packetCount <= 5 || packetCount%100 == 0 {
				l.Debug("RX MASQUE→netstack", "packet", packetCount, "bytes", n)
			}

			if err := device.WritePacket(buf[:n]); err != nil {
				l.Error("error writing to TUN device", "error", err, "packet_size", n)
			}
		}
	}()

	// Connection monitoring and recovery goroutine
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case <-connectionDown:
				l.Warn("MASQUE connection lost, starting recovery process...")

				// Give time for error messages to settle
				time.Sleep(1 * time.Second)

				// Try to reconnect with exponential backoff
				for attempt := 1; attempt <= 5 && ctx.Err() == nil; attempt++ {
					backoff := time.Duration(attempt) * 2 * time.Second
					l.Info("Reconnection attempt", "attempt", attempt, "backoff", backoff)

					time.Sleep(backoff)

					if ctx.Err() != nil {
						return
					}

					// Close the old broken adapter
					l.Info("Closing broken MASQUE adapter")
					adapter.Close()

					// Create a new MASQUE adapter from scratch
					l.Info("Creating new MASQUE adapter with fresh handshake")
					newAdapter, err := factory()
					if err != nil {
						l.Warn("Failed to create new MASQUE adapter", "attempt", attempt, "error", err)
						continue
					}

					// Test the new connection
					testBuf := make([]byte, 64)
					readDone := make(chan error, 1)
					go func() {
						_, readErr := newAdapter.Read(testBuf)
						readDone <- readErr
					}()

					var testErr error
					select {
					case testErr = <-readDone:
						// Read completed
					case <-time.After(3 * time.Second):
						testErr = context.DeadlineExceeded
					}

					if testErr == nil || !isConnectionError(testErr) {
						l.Info("New MASQUE adapter created successfully", "attempt", attempt)
						// Replace the old adapter with the new one
						*adapter = *newAdapter
						connectionBroken.Store(false)
						break
					} else {
						l.Warn("New MASQUE adapter test failed", "attempt", attempt, "error", testErr)
						newAdapter.Close()
					}
				}

				// If all attempts failed, log and continue trying
				if connectionBroken.Load() && ctx.Err() == nil {
					l.Error("All reconnection attempts failed, connection remains broken")
					// Trigger another reconnection attempt after a longer delay
					time.Sleep(10 * time.Second)
					if ctx.Err() == nil {
						select {
						case connectionDown <- true:
						default:
						}
					}
				}
			}
		}
	}()
}
