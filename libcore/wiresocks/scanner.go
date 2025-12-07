package wiresocks

import (
	"context"
	"errors"
	"log/slog"
	"net"
	"net/netip"
	"strconv"
	"strings"
	"time"

	"github.com/bepass-org/vwarp/ipscanner"
	"github.com/bepass-org/vwarp/warp"
)

type ScanOptions struct {
	Endpoints    string
	ScannerPorts string
	V4           bool
	V6           bool
	MaxRTT       time.Duration
	ScanTimeout  time.Duration
	PrivateKey   string
	PublicKey    string
}

func RunScan(ctx context.Context, l *slog.Logger, opts ScanOptions) (result []ipscanner.IPInfo, err error) {
	scanCtx, cancel := context.WithCancel(ctx)
	defer cancel()

	// Stop the scan as soon as the first good IP is found.
	const desiredIPs = 1

	// Initialize scanner options
	scannerOptions := []ipscanner.Option{
		ipscanner.WithLogger(l.With(slog.String("subsystem", "scanner"))),
		ipscanner.WithWarpPrivateKey(opts.PrivateKey),
		ipscanner.WithWarpPeerPublicKey(opts.PublicKey),
		ipscanner.WithUseIPv4(opts.V4),
		ipscanner.WithUseIPv6(opts.V6),
		ipscanner.WithMaxDesirableRTT(opts.MaxRTT * time.Second),
		ipscanner.WithConcurrentScanners(10),
		ipscanner.WithStopOnFirstGoodIPs(desiredIPs),
		ipscanner.WithBucketSize(1),
		ipscanner.WithTCPPingFilterRTT(300 * time.Millisecond),
		ipscanner.WithScanTimeout(opts.ScanTimeout),
	}

	// Supports:
	// 1. a single or multiple ip:port separated by "," (e.g., 192.168.1.1:8080, [2001:db8::1]:2408)
	// 2. one or multiple ip ranges (CIDR) separated by "," (e.g., 192.168.1.0/24, 2606:4700:d0::/48)
	// 3. a single or multiple ip separated by "," (e.g., 192.168.1.1, 2001:db8::1)
	// 4. a single domain with port (e.g., example.com:8443)
	// 5. a single domain without port (e.g., example.com)

	// If user does not specify custom endpoints, use the default WARP IP ranges for scanning.
	// This ensures that both IPv4 and IPv6 ranges are scanned if enabled.
	if opts.Endpoints == "" {
		l.Debug("no endpoints provided, using default WARP prefixes for scanning")
		scannerOptions = append(scannerOptions, ipscanner.WithCidrList(warp.WarpPrefixes()))
	} else {
		parts := strings.Split(opts.Endpoints, ",")
		for _, part := range parts {
			trimmedPart := strings.TrimSpace(part)
			if trimmedPart == "" {
				continue // Skip empty parts
			}

			// Case 1: Is it a valid CIDR? (e.g., 192.168.1.0/24)
			if prefix, err := netip.ParsePrefix(trimmedPart); err == nil {
				scannerOptions = append(scannerOptions, ipscanner.WithAppendCidrList(prefix))
				continue
			}

			// Case 2 & 3: Is it a valid ip:port or domain:port? (e.g., 1.1.1.1:8080 or example.com:8443)
			_, portStr, err := net.SplitHostPort(trimmedPart)
			if err == nil {
				// Validate the port number.
				port, err := strconv.Atoi(portStr)
				if err != nil || port < 0 || port > 65535 {
					return nil, errors.New("invalid port number: " + portStr)
				}
				scannerOptions = append(scannerOptions, ipscanner.WithAppendCustomEndpoint(trimmedPart))
				continue
			}

			// Case 4: Is it a single IP address without a port? (e.g., 192.168.1.1)
			// Use ":0" to signal random WARP port selection.
			if _, err := netip.ParseAddr(trimmedPart); err == nil {
				endpointWithPort := net.JoinHostPort(trimmedPart, "0")
				scannerOptions = append(scannerOptions, ipscanner.WithAppendCustomEndpoint(endpointWithPort))
				continue
			}

			// Case 5: Is it a domain without a port? (e.g., example.com)
			if strings.Contains(trimmedPart, ".") && !strings.ContainsAny(trimmedPart, "/:") {
				endpointWithPort := net.JoinHostPort(trimmedPart, "0")
				scannerOptions = append(scannerOptions, ipscanner.WithAppendCustomEndpoint(endpointWithPort))
				continue
			}

			// Format is invalid
			return nil, errors.New("invalid endpoint format: " + trimmedPart)
		}
	}

	// Set default scan ports
	if opts.ScannerPorts != "" {
		scannerOptions = append(scannerOptions, ipscanner.WithCustomScanPorts(opts.ScannerPorts))
	}

	scanner := ipscanner.NewScanner(scannerOptions...)

	// Blocks
	scanner.Run(scanCtx)

	// After the run, get the results.
	ipList := scanner.GetAvailableIPs()

	// Check if we found any IPs.
	if len(ipList) == 0 {
		// If the context was canceled, that's the primary error.
		if scanCtx.Err() != nil {
			return nil, scanCtx.Err()
		}
		// Otherwise, the scan finished without finding anything.
		return nil, errors.New("scan finished with no working IPs found")
	}

	// Success: return the found IPs (up to the desired count).
	count := len(ipList)
	if count > desiredIPs {
		count = desiredIPs
	}
	return ipList[:count], nil
}
