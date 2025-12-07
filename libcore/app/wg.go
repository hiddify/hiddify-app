package app

import (
	"bufio"
	"bytes"
	"context"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/bepass-org/vwarp/wireguard/conn"
	"github.com/bepass-org/vwarp/wireguard/device"
	"github.com/bepass-org/vwarp/wireguard/preflightbind"
	wgtun "github.com/bepass-org/vwarp/wireguard/tun"
	"github.com/bepass-org/vwarp/wireguard/tun/netstack"
	"github.com/bepass-org/vwarp/wiresocks"
)

func usermodeTunTest(ctx context.Context, l *slog.Logger, tnet *netstack.Net, url string) error {
	// Wait a bit after handshake to ensure connection is stable
	time.Sleep(2 * time.Second)

	l.Info("testing connectivity", "url", url)

	client := http.Client{
		Timeout: 15 * time.Second,
		Transport: &http.Transport{
			DialContext: tnet.DialContext,
		},
	}

	resp, err := client.Get(url)
	if err != nil {
		l.Error("connectivity test failed", "error", err, "url", url)
		return err
	}
	defer resp.Body.Close()

	l.Info("connectivity test completed successfully", "status", resp.StatusCode, "url", url)
	return nil
}

func waitHandshake(ctx context.Context, l *slog.Logger, dev *device.Device) error {
	lastHandshakeSecs := "0"
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		get, err := dev.IpcGet()
		if err != nil {
			continue
		}
		scanner := bufio.NewScanner(strings.NewReader(get))
		for scanner.Scan() {
			line := scanner.Text()
			if line == "" {
				break
			}

			key, value, ok := strings.Cut(line, "=")
			if !ok {
				continue
			}

			if key == "last_handshake_time_sec" {
				lastHandshakeSecs = value
				break
			}
		}
		if lastHandshakeSecs != "0" {
			l.Debug("handshake complete")
			break
		}

		l.Debug("waiting on handshake")
		time.Sleep(1 * time.Second)
	}

	return nil
}

func establishWireguard(l *slog.Logger, conf *wiresocks.Configuration, tunDev wgtun.Device, fwmark uint32, t string, AtomicNoizeConfig *preflightbind.AtomicNoizeConfig, proxyAddress string) error {
	// create the IPC message to establish the wireguard conn
	var request bytes.Buffer

	request.WriteString(fmt.Sprintf("private_key=%s\n", conf.Interface.PrivateKey))
	if fwmark != 0 {
		request.WriteString(fmt.Sprintf("fwmark=%d\n", fwmark))
	}

	for _, peer := range conf.Peers {
		request.WriteString(fmt.Sprintf("public_key=%s\n", peer.PublicKey))
		request.WriteString(fmt.Sprintf("persistent_keepalive_interval=%d\n", peer.KeepAlive))
		request.WriteString(fmt.Sprintf("preshared_key=%s\n", peer.PreSharedKey))
		request.WriteString(fmt.Sprintf("endpoint=%s\n", peer.Endpoint))

		// Only set trick if AtomicNoize is not being used
		if AtomicNoizeConfig == nil {
			request.WriteString(fmt.Sprintf("trick=%s\n", t))
		} else {
			// Set trick to empty/t0 to disable old obfuscation when using AtomicNoize
			request.WriteString("trick=t0\n")
		}

		request.WriteString(fmt.Sprintf("reserved=%d,%d,%d\n", peer.Reserved[0], peer.Reserved[1], peer.Reserved[2]))

		for _, cidr := range peer.AllowedIPs {
			request.WriteString(fmt.Sprintf("allowed_ip=%s\n", cidr))
		}
	}

	// Create the appropriate bind based on configuration
	var bind conn.Bind

	// If proxy address is provided, create a proxy-aware bind
	if proxyAddress != "" {
		l.Info("using SOCKS proxy for WireGuard traffic", "proxy", proxyAddress)
		bind = conn.NewProxyBind(proxyAddress)
	} else {
		bind = conn.NewDefaultBind()
	}

	// If AtomicNoizeConfig configuration is provided, wrap the bind
	if AtomicNoizeConfig != nil {
		l.Info("using AtomicNoize WireGuard obfuscation")

		// Extract port from the first peer endpoint
		preflightPort := 443 // default fallback
		if len(conf.Peers) > 0 && conf.Peers[0].Endpoint != "" {
			_, portStr, err := net.SplitHostPort(conf.Peers[0].Endpoint)
			if err == nil {
				if port, err := strconv.Atoi(portStr); err == nil {
					preflightPort = port
				}
			}
		}

		l.Info("using preflight port", "port", preflightPort)
		amnesiaBind, err := preflightbind.NewWithAtomicNoize(
			bind, // Use the already created bind instead of creating a new one
			AtomicNoizeConfig,
			preflightPort,        // extracted port for preflight packets
			100*time.Millisecond, // minimum interval between preflights (reduced from 1 second)
		)
		if err != nil {
			l.Error("failed to create AtomicNoize bind", "error", err)
			return err
		}
		bind = amnesiaBind
	}

	dev := device.NewDevice(
		tunDev,
		bind,
		device.NewSLogger(l.With("subsystem", "wireguard-go")),
	)

	if err := dev.IpcSet(request.String()); err != nil {
		return err
	}

	if err := dev.Up(); err != nil {
		return err
	}

	ctx, cancel := context.WithDeadline(context.Background(), time.Now().Add(15*time.Second))
	defer cancel()
	if err := waitHandshake(ctx, l, dev); err != nil {
		dev.BindClose()
		dev.Close()
		return err
	}

	return nil
}
