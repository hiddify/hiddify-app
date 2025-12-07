package warp

import (
	"context"
	"encoding/hex"
	"errors"
	"net"
	"strings"
	"time"
)

// SendRawQUICInitial sends a single UDP datagram (your QUIC Initial)
// to host:port. hexPayload may start with "0x" or be plain hex.
func SendRawQUICInitial(ctx context.Context, host string, port int, hexPayload string) error {
	h := strings.TrimSpace(hexPayload)
	if strings.HasPrefix(h, "0x") || strings.HasPrefix(h, "0X") {
		h = h[2:]
	}
	payload, err := hex.DecodeString(h)
	if err != nil {
		return err
	}
	if len(payload) == 0 {
		return errors.New("empty payload")
	}

	raddr, err := net.ResolveUDPAddr("udp", net.JoinHostPort(host, itoa(port)))
	if err != nil {
		return err
	}

	// 0-bind local UDP; OS picks an ephemeral port.
	conn, err := net.DialUDP("udp", nil, raddr)
	if err != nil {
		return err
	}
	defer conn.Close()

	// Short deadline; we don't wait for a response here.
	_ = conn.SetWriteDeadline(time.Now().Add(500 * time.Millisecond))

	// Optional: honor context cancellation.
	done := make(chan struct{})
	var werr error
	go func() {
		_, werr = conn.Write(payload)
		close(done)
	}()

	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-done:
		return werr
	}
}

// itoa without pulling strconv for one small thing.
func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var b [12]byte
	i := len(b)
	neg := n < 0
	if neg {
		n = -n
	}
	for n > 0 {
		i--
		b[i] = byte('0' + n%10)
		n /= 10
	}
	if neg {
		i--
		b[i] = '-'
	}
	return string(b[i:])
}
