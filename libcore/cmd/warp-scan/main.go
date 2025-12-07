package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/netip"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/bepass-org/vwarp/ipscanner"
	"github.com/bepass-org/vwarp/masque"
	"github.com/bepass-org/vwarp/warp"

	"github.com/carlmjohnson/versioninfo"
	"github.com/fatih/color"
	"github.com/peterbourgon/ff/v4"
	"github.com/peterbourgon/ff/v4/ffhelp"
	"github.com/rodaine/table"
)

const appName = "warp-scanner"

var version = versioninfo.Short()

// A known public IPv6 address for connectivity testing.
var googlev6DNSAddr80 = netip.MustParseAddrPort("[2001:4860:4860::8888]:80")

// Configurable parameters
type config struct {
	UseIPv4          bool
	UseIPv6          bool
	Cidrs            []string
	CidrsFile        string
	Endpoints        []string
	EndpointsFile    string
	NoDefaultCidrs   bool
	BucketSize       int
	TestIP           string
	AllPorts         bool
	Concurrency      int
	StopOnCount      int
	ScanTimeout      time.Duration
	MaxRTT           time.Duration
	TCPPingFilterRTT time.Duration
	PrivateKey       string
	PeerPublicKey    string
	PresharedKey     string
	LogLevel         string
	OutputFile       string
	OutputJSON       bool
	ShowVersion      bool
	// MASQUE-specific options
	EnableMasque bool
	MasqueOnly   bool
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, os.Args[1:], os.Stdout, os.Stderr); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, args []string, stdout, stderr io.Writer) error {
	cfg, err := parseConfig(args, stderr)
	if err != nil {
		if errors.Is(err, ff.ErrHelp) {
			return nil // Exit gracefully on --help
		}
		return err
	}

	var programLevel = new(slog.LevelVar)
	switch strings.ToLower(cfg.LogLevel) {
	case "debug":
		programLevel.Set(slog.LevelDebug)
	case "warn":
		programLevel.Set(slog.LevelWarn)
	case "error":
		programLevel.Set(slog.LevelError)
	default:
		programLevel.Set(slog.LevelInfo)
	}
	logger := slog.New(slog.NewTextHandler(stderr, &slog.HandlerOptions{Level: programLevel}))

	scanner, err := buildScanner(cfg, logger)
	if err != nil {
		return fmt.Errorf("failed to build scanner: %w", err)
	}

	logger.Info("Starting scanner...", "timeout", cfg.ScanTimeout, "target_count", cfg.StopOnCount)
	scanner.Run(ctx)
	logger.Info("Scan finished.")

	results := scanner.GetAvailableIPs()
	return writeOutput(cfg.OutputFile, stdout, results, cfg.OutputJSON)
}

func parseConfig(args []string, stderr io.Writer) (*config, error) {
	fs := ff.NewFlagSet(appName)
	cfg := &config{}

	// Flags
	fs.BoolVar(&cfg.UseIPv4, '4', "ipv4", "Scan IPv4 addresses.")
	fs.BoolVar(&cfg.UseIPv6, '6', "ipv6", "Scan IPv6 addresses.")
	fs.StringListVar(&cfg.Cidrs, 0, "cidrs", "Comma-separated list of CIDRs to scan (e.g., 1.2.3.0/24, 2001:db8::/32).")
	fs.StringVar(&cfg.CidrsFile, 0, "cidrs-file", "", "Path to a file containing CIDRs to scan, one per line.")
	fs.StringListVar(&cfg.Endpoints, 0, "endpoints", "Comma-separated list of specific endpoints to scan (e.g., 1.1.1.1:2408, [2001:db8::1]:2408).")
	fs.StringVar(&cfg.EndpointsFile, 0, "endpoints-file", "", "Path to a file containing specific endpoints to scan, one per line.")
	fs.BoolVar(&cfg.NoDefaultCidrs, 0, "no-default-cidrs", "Do not use the default list of WARP CIDRs.")
	fs.IntVar(&cfg.BucketSize, 0, "bucket-size", 1, "Number of random IPs to scan from each /24 or /120 subnet.")
	fs.StringVar(&cfg.TestIP, 0, "test-ip", "", "Test all known WARP ports for a single IP address (exclusive mode).")
	fs.BoolVar(&cfg.AllPorts, 0, "all-ports", "When used with --test-ip, tests all 65535 ports.")
	fs.IntVar(&cfg.Concurrency, 'c', "concurrency", 100, "Number of concurrent scanners.")
	fs.IntVar(&cfg.StopOnCount, 'n', "count", 0, "Stop after finding this many good IPs (0 for unlimited).")
	fs.DurationVar(&cfg.ScanTimeout, 't', "timeout", 0, "Stop scan after this duration. 0 for unlimited.")
	fs.DurationVar(&cfg.MaxRTT, 0, "max-rtt", 1*time.Second, "Maximum RTT for an IP to be considered 'good' in the final result.")
	fs.DurationVar(&cfg.TCPPingFilterRTT, 0, "tcp-rtt", 300*time.Millisecond, "RTT limit for the initial TCP ping filter stage.")
	fs.StringVar(&cfg.PrivateKey, 0, "private-key", "yGXeX7gMyUIZmK5QIgC7+XX5USUSskQvBYiQ6LdkiXI=", "WARP private key.")
	fs.StringVar(&cfg.PeerPublicKey, 0, "peer-public-key", "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=", "WARP peer public key.")
	fs.StringVar(&cfg.PresharedKey, 0, "preshared-key", "", "WARP preshared key.")
	fs.StringVar(&cfg.LogLevel, 0, "log-level", "info", "Log level (debug, info, warn, error).")
	fs.StringVar(&cfg.OutputFile, 'o', "output", "", "Path to save the output. Prints to stdout if empty.")
	fs.BoolVar(&cfg.OutputJSON, 0, "json", "Output results in JSON format.")
	fs.BoolVar(&cfg.ShowVersion, 0, "version", "Display version information.")
	// MASQUE flags
	fs.BoolVar(&cfg.EnableMasque, 0, "masque", "Include MASQUE endpoints in the scan.")
	fs.BoolVar(&cfg.MasqueOnly, 0, "masque-only", "Scan only MASQUE endpoints (excludes WireGuard endpoints).")

	if err := ff.Parse(fs, args, ff.WithEnvVarPrefix("WARP")); err != nil {
		if errors.Is(err, ff.ErrHelp) {
			fmt.Fprintf(stderr, "USAGE\n  %s [FLAGS]\n\n", fs.GetName())
			fmt.Fprintf(stderr, "DESCRIPTION\n")
			fmt.Fprintf(stderr, "  A tool to find optimal Cloudflare WARP endpoints with IPv4 and IPv6 support.\n\n")
			fmt.Fprintf(stderr, "MODES\n")
			fmt.Fprintf(stderr, "  Default (Strategic Scan):\n")
			fmt.Fprintf(stderr, "    Scans random IPs from WARP CIDR ranges using a multi-stage pipeline.\n")
			fmt.Fprintf(stderr, "    1. IP Generation: Samples IPs from each /24 (IPv4) or /120 (IPv6) subnet (--bucket-size).\n")
			fmt.Fprintf(stderr, "    2. TCP Ping Filter: Discards IPs with high latency (--tcp-rtt).\n")
			fmt.Fprintf(stderr, "    3. WARP Handshake: Verifies the remaining endpoints.\n\n")
			fmt.Fprintf(stderr, "  Port Test (--test-ip):\n")
			fmt.Fprintf(stderr, "    Scans known WARP ports on a single specified IP to find a working endpoint.\n")
			fmt.Fprintf(stderr, "    Use --all-ports to test every port instead of just the known ones.\n\n")
			fmt.Fprintf(stderr, "FLAGS\n")
			fmt.Fprintf(stderr, "%s\n", ffhelp.Flags(fs))
			return nil, ff.ErrHelp
		}
		return nil, err
	}

	if cfg.ShowVersion {
		fmt.Fprintf(stderr, "%s %s\n", appName, version)
		return nil, ff.ErrHelp
	}

	return cfg, nil
}

// canConnectIPv6 checks for basic IPv6 internet connectivity.
func canConnectIPv6(remoteAddr netip.AddrPort) bool {
	dialer := net.Dialer{
		Timeout: 5 * time.Second,
	}
	conn, err := dialer.Dial("tcp6", remoteAddr.String())
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

func buildScanner(cfg *config, logger *slog.Logger) (*ipscanner.IPScanner, error) {
	// Consolidate all user-provided inputs
	if cfg.EndpointsFile != "" {
		lines, err := readFileLines(cfg.EndpointsFile)
		if err != nil {
			return nil, fmt.Errorf("failed to read endpoints file: %w", err)
		}
		cfg.Endpoints = append(cfg.Endpoints, lines...)
	}
	if cfg.CidrsFile != "" {
		lines, err := readFileLines(cfg.CidrsFile)
		if err != nil {
			return nil, fmt.Errorf("failed to read cidrs file: %w", err)
		}
		cfg.Cidrs = append(cfg.Cidrs, lines...)
	}

	// Normalize endpoints: allow users to pass multiple endpoints in a single
	// comma-separated flag value (e.g. --endpoints "1.1.1.1:2408,2.2.2.2:2408").
	// Split any comma-containing entries into individual endpoints and trim
	// whitespace. This prevents later parsing/inference from seeing combined
	// strings and failing to infer IP families.
	if len(cfg.Endpoints) > 0 {
		var normalized []string
		for _, e := range cfg.Endpoints {
			parts := strings.Split(e, ",")
			for _, p := range parts {
				p = strings.TrimSpace(p)
				if p != "" {
					normalized = append(normalized, p)
				}
			}
		}
		cfg.Endpoints = normalized
	}

	// Infer required IP versions from user input if not explicitly set
	userInputProvided := len(cfg.Endpoints) > 0 || len(cfg.Cidrs) > 0 || cfg.TestIP != ""
	if !cfg.UseIPv4 && !cfg.UseIPv6 {
		if !userInputProvided {
			// No user input and no flags, so enable both for default scan
			cfg.UseIPv4, cfg.UseIPv6 = true, true
			logger.Debug("Neither -4 nor -6 specified, enabling both for default WARP CIDR scan.")
		} else {
			// Infer from the input itself
			for _, c := range cfg.Cidrs {
				if p, err := netip.ParsePrefix(c); err == nil {
					if p.Addr().Is4() {
						cfg.UseIPv4 = true
					} else {
						cfg.UseIPv6 = true
					}
				}
			}
			for _, e := range cfg.Endpoints {
				host, _, _ := net.SplitHostPort(e)
				if host == "" {
					host = e
				}
				if addr, err := netip.ParseAddr(host); err == nil {
					if addr.Is4() {
						cfg.UseIPv4 = true
					} else {
						cfg.UseIPv6 = true
					}
				}
			}
			if addr, err := netip.ParseAddr(cfg.TestIP); err == nil {
				if addr.Is4() {
					cfg.UseIPv4 = true
				} else {
					cfg.UseIPv6 = true
				}
			}
			logger.Debug("Inferred IP versions from input", "ipv4", cfg.UseIPv4, "ipv6", cfg.UseIPv6)
		}
	}
	// Final check to ensure at least one IP version is active
	if !cfg.UseIPv4 && !cfg.UseIPv6 {
		return nil, errors.New("IPv4 and IPv6 scanning are both disabled; nothing to do")
	}

	opts := []ipscanner.Option{
		ipscanner.WithLogger(logger),
		ipscanner.WithWarpPrivateKey(cfg.PrivateKey),
		ipscanner.WithWarpPeerPublicKey(cfg.PeerPublicKey),
		ipscanner.WithWarpPreSharedKey(cfg.PresharedKey),
		ipscanner.WithUseIPv4(cfg.UseIPv4),
		ipscanner.WithUseIPv6(cfg.UseIPv6),
		ipscanner.WithMaxDesirableRTT(cfg.MaxRTT),
		ipscanner.WithTCPPingFilterRTT(cfg.TCPPingFilterRTT),
		ipscanner.WithBucketSize(cfg.BucketSize),
		ipscanner.WithConcurrentScanners(cfg.Concurrency),
		ipscanner.WithScanTimeout(cfg.ScanTimeout),
		ipscanner.WithStopOnFirstGoodIPs(cfg.StopOnCount),
		// MASQUE-specific options
		ipscanner.WithEnableMasqueScanning(cfg.EnableMasque),
		ipscanner.WithMasqueOnly(cfg.MasqueOnly),
	}

	// Handle the dedicated port test mode
	if cfg.TestIP != "" {
		var portsToTest []uint16
		if cfg.AllPorts {
			logger.Info("Preparing to test all 65535 ports. This may take a very long time.", "ip", cfg.TestIP)
			portsToTest = make([]uint16, 65535)
			for i := 0; i < 65535; i++ {
				portsToTest[i] = uint16(i + 1)
			}
		} else {
			portsToTest = warp.GetWarpPorts()
		}
		opts = append(opts, ipscanner.WithTestEndpointPorts(cfg.TestIP, portsToTest))
	} else {
		// Only add CIDRs and custom endpoints if not in port test mode
		var allCidrs []netip.Prefix

		// If the user provided endpoints or explicit CIDRs, do NOT inject the default WARP CIDRs.
		userProvidedCidrs := len(cfg.Cidrs) > 0
		userProvidedEndpoints := len(cfg.Endpoints) > 0

		if !cfg.NoDefaultCidrs && !userProvidedCidrs && !userProvidedEndpoints {
			if cfg.MasqueOnly {
				// Use MASQUE CIDR ranges
				logger.Info("Using MASQUE endpoint ranges for scanning")
				for _, cidr := range masque.DefaultIPv4Ranges() {
					if p, err := netip.ParsePrefix(cidr); err == nil && cfg.UseIPv4 {
						allCidrs = append(allCidrs, p)
					}
				}
				for _, cidr := range masque.DefaultIPv6Ranges() {
					if p, err := netip.ParsePrefix(cidr); err == nil && cfg.UseIPv6 {
						allCidrs = append(allCidrs, p)
					}
				}
			} else if cfg.EnableMasque {
				// Use both WARP and MASQUE CIDR lists
				logger.Info("Using both WARP and MASQUE endpoint ranges for scanning")
				allCidrs = append(allCidrs, warp.WarpPrefixes()...)
				for _, cidr := range masque.DefaultIPv4Ranges() {
					if p, err := netip.ParsePrefix(cidr); err == nil && cfg.UseIPv4 {
						allCidrs = append(allCidrs, p)
					}
				}
				for _, cidr := range masque.DefaultIPv6Ranges() {
					if p, err := netip.ParsePrefix(cidr); err == nil && cfg.UseIPv6 {
						allCidrs = append(allCidrs, p)
					}
				}
			} else {
				// No user input -> use default WARP CIDR list
				allCidrs = append(allCidrs, warp.WarpPrefixes()...)
			}
		}

		// Append any user-provided CIDRs (explicit user CIDRs take precedence)
		for _, c := range cfg.Cidrs {
			p, err := netip.ParsePrefix(c)
			if err != nil {
				logger.Warn("invalid cidr, skipping", "cidr", c, "error", err)
				continue
			}
			allCidrs = append(allCidrs, p)
		}

		opts = append(opts, ipscanner.WithCidrList(allCidrs))
		// Always pass custom endpoints (if any). When endpoints are provided and no CIDRs
		// are present, the engine will scan only those endpoints.
		opts = append(opts, ipscanner.WithCustomEndpoints(cfg.Endpoints))
		if cfg.AllPorts {
			logger.Warn("--all-ports flag has no effect without --test-ip.")
		}
	}

	return ipscanner.NewScanner(opts...), nil
}

func writeOutput(path string, stdout io.Writer, results []ipscanner.IPInfo, useJSON bool) error {
	writer := stdout
	if path != "" {
		f, err := os.Create(path)
		if err != nil {
			return fmt.Errorf("failed to create output file: %w", err)
		}
		defer f.Close()
		writer = f
	}

	if useJSON {
		encoder := json.NewEncoder(writer)
		encoder.SetIndent("", "  ")
		return encoder.Encode(results)
	}

	if len(results) == 0 {
		fmt.Fprintln(writer, "No working IPs found.")
		return nil
	}

	headerFmt := color.New(color.FgGreen, color.Underline).SprintfFunc()
	columnFmt := color.New(color.FgYellow).SprintfFunc()

	tbl := table.New("Address", "RTT (ping)", "Time")
	tbl.WithHeaderFormatter(headerFmt).WithFirstColumnFormatter(columnFmt)
	tbl.WithWriter(writer)

	for _, info := range results {
		tbl.AddRow(info.AddrPort, info.RTT, info.CreatedAt.Format(time.DateTime))
	}
	tbl.Print()
	return nil
}

func readFileLines(path string) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line != "" && !strings.HasPrefix(line, "#") {
			lines = append(lines, line)
		}
	}
	return lines, scanner.Err()
}
