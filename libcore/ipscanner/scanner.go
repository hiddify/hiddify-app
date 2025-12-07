package ipscanner

import (
	"context"
	"crypto/tls"
	"log/slog"
	"net"
	"net/http"
	"net/netip"
	"strconv"
	"strings"
	"time"

	"github.com/bepass-org/vwarp/ipscanner/engine"
	"github.com/bepass-org/vwarp/ipscanner/statute"
	"github.com/bepass-org/vwarp/warp"
	"github.com/noql-net/certpool"
)

type IPScanner struct {
	options statute.ScannerOptions
	log     *slog.Logger
	engine  *engine.Engine
}

const defaultDnsResolveTimeout = 5 * time.Second

func NewScanner(options ...Option) *IPScanner {
	p := &IPScanner{
		options: statute.ScannerOptions{
			UseIPv4:            true,
			UseIPv6:            true,
			CidrList:           []netip.Prefix{},
			CustomEndpoints:    []netip.AddrPort{},
			Logger:             slog.Default(),
			InsecureSkipVerify: true,
			UseHTTP2:           false,
			DisableCompression: false,
			HTTPPath:           "/",
			Referrer:           "",
			UserAgent:          "Chrome/80.0.3987.149",
			Hostname:           "wWw.ClOuDflarRe.Com",
			WarpPresharedKey:   "",
			WarpPeerPublicKey:  "",
			WarpPrivateKey:     "",
			Port:               2408, // Default to 0 for WARP, allowing random port selection.
			DefaultScanPorts:   warp.GetWarpPorts(),
			IcmpPing:           false,
			TcpPing:            true,
			TCPPingPort:        443,
			BucketSize:         5,
			ICMPPingFilterRTT:  400 * time.Millisecond,
			TCPPingFilterRTT:   300 * time.Millisecond,
			IPQueueSize:        0xFFFF, // Effectively unlimited to collect all results.
			MaxDesirableRTT:    400 * time.Millisecond,
			IPQueueTTL:         30 * time.Second,
			ConnectionTimeout:  1 * time.Second,
			HandshakeTimeout:   1 * time.Second,
			TlsVersion:         tls.VersionTLS13,
			ConcurrentScanners: 100,
			ScanTimeout:        0, // 0 means no timeout
			StopOnFirstGoodIPs: 0, // 0 means do not stop
			TestPortsForIPs:    make(map[netip.Addr][]uint16),
		},
		log: slog.Default(),
	}

	for _, option := range options {
		option(p)
	}

	// Use default WARP ranges if CIDR List is empty
	if len(p.options.CidrList) == 0 && len(p.options.CustomEndpoints) == 0 && len(p.options.TestPortsForIPs) == 0 {
		p.log.Debug("Using default Warp CIDR list")
		p.options.CidrList = statute.DefaultCFRanges()
	}

	// Set default dialers and HTTP client using closures to capture instance-specific options,
	// only if they haven't been overridden by the user.
	if p.options.RawDialerFunc == nil {
		p.options.RawDialerFunc = p.defaultDialerFunc()
	}
	if p.options.TLSDialerFunc == nil {
		p.options.TLSDialerFunc = p.defaultTLSDialerFunc()
	}
	if p.options.HttpClientFunc == nil {
		p.options.HttpClientFunc = p.defaultHTTPClientFunc
	}

	return p
}

func WithScanTimeout(timeout time.Duration) Option {
	return func(i *IPScanner) {
		i.options.ScanTimeout = timeout
	}
}

// WithStopOnFirstGoodIPs sets the scanner to stop after finding a specific number of working IPs.
func WithStopOnFirstGoodIPs(count int) Option {
	return func(i *IPScanner) {
		if count > 0 {
			i.options.StopOnFirstGoodIPs = count
		}
	}
}

func (i *IPScanner) defaultDialerFunc() statute.TDialerFunc {
	return func(ctx context.Context, network, addr string) (net.Conn, error) {
		d := &net.Dialer{
			Timeout: i.options.ConnectionTimeout,
		}
		return d.DialContext(ctx, network, addr)
	}
}

func (i *IPScanner) defaultTLSDialerFunc() statute.TDialerFunc {
	return func(ctx context.Context, network, addr string) (net.Conn, error) {
		rawConn, err := i.options.RawDialerFunc(ctx, network, addr)
		if err != nil {
			return nil, err
		}

		host, _, err := net.SplitHostPort(addr)
		if err != nil {
			// Fallback or error, for simplicity let's use the provided addr as SNI
			host = addr
		}
		if i.options.Hostname != "" {
			host = i.options.Hostname
		}

		config := &tls.Config{
			InsecureSkipVerify: i.options.InsecureSkipVerify,
			ServerName:         host,
			MinVersion:         i.options.TlsVersion,
			MaxVersion:         i.options.TlsVersion,
			NextProtos:         []string{"http/1.1"},
			RootCAs:            certpool.Roots(),
		}
		if i.options.UseHTTP2 {
			config.NextProtos = []string{"h2", "http/1.1"}
		}

		tlsClientConn := tls.Client(rawConn, config)
		if err := tlsClientConn.SetDeadline(time.Now().Add(i.options.HandshakeTimeout)); err != nil {
			rawConn.Close()
			return nil, err
		}
		if err := tlsClientConn.Handshake(); err != nil {
			rawConn.Close()
			return nil, err
		}
		tlsClientConn.SetDeadline(time.Time{})
		return tlsClientConn, nil
	}
}

func (i *IPScanner) defaultHTTPClientFunc(rawDialer statute.TDialerFunc, tlsDialer statute.TDialerFunc, targetAddr ...string) *http.Client {
	transport := &http.Transport{
		DialContext:         rawDialer,
		DialTLSContext:      tlsDialer,
		ForceAttemptHTTP2:   i.options.UseHTTP2,
		DisableCompression:  i.options.DisableCompression,
		MaxIdleConnsPerHost: -1,
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: i.options.InsecureSkipVerify,
			ServerName:         i.options.Hostname,
		},
	}
	return &http.Client{
		Transport: transport,
		Timeout:   i.options.ConnectionTimeout,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
}

type Option func(*IPScanner)

func WithUseIPv4(useIPv4 bool) Option {
	return func(i *IPScanner) {
		i.options.UseIPv4 = useIPv4
	}
}

func WithUseIPv6(useIPv6 bool) Option {
	return func(i *IPScanner) {
		i.options.UseIPv6 = useIPv6
	}
}

func WithDialer(d statute.TDialerFunc) Option {
	return func(i *IPScanner) {
		i.options.RawDialerFunc = d
	}
}

func WithTLSDialer(t statute.TDialerFunc) Option {
	return func(i *IPScanner) {
		i.options.TLSDialerFunc = t
	}
}

func WithHttpClientFunc(h statute.THTTPClientFunc) Option {
	return func(i *IPScanner) {
		i.options.HttpClientFunc = h
	}
}

func WithUseHTTP2(useHTTP2 bool) Option {
	return func(i *IPScanner) {
		i.options.UseHTTP2 = useHTTP2
	}
}

func WithDisableCompression(disableCompression bool) Option {
	return func(i *IPScanner) {
		i.options.DisableCompression = disableCompression
	}
}

func WithHttpPath(path string) Option {
	return func(i *IPScanner) {
		i.options.HTTPPath = path
	}
}

func WithReferrer(referrer string) Option {
	return func(i *IPScanner) {
		i.options.Referrer = referrer
	}
}

func WithUserAgent(userAgent string) Option {
	return func(i *IPScanner) {
		i.options.UserAgent = userAgent
	}
}

func WithLogger(logger *slog.Logger) Option {
	return func(i *IPScanner) {
		i.log = logger
		i.options.Logger = logger
	}
}

func WithInsecureSkipVerify(insecureSkipVerify bool) Option {
	return func(i *IPScanner) {
		i.options.InsecureSkipVerify = insecureSkipVerify
	}
}

func WithHostname(hostname string) Option {
	return func(i *IPScanner) {
		i.options.Hostname = hostname
	}
}

func WithPort(port uint16) Option {
	return func(i *IPScanner) {
		i.options.Port = port
	}
}

func WithCidrList(cidrList []netip.Prefix) Option {
	return func(i *IPScanner) {
		i.options.CidrList = cidrList
	}
}

func WithAppendCidrList(cidr netip.Prefix) Option {
	return func(i *IPScanner) {
		i.options.CidrList = append(i.options.CidrList, cidr)
	}
}

func WithIPQueueSize(size int) Option {
	return func(i *IPScanner) {
		i.options.IPQueueSize = size
	}
}

func WithMaxDesirableRTT(threshold time.Duration) Option {
	return func(i *IPScanner) {
		i.options.MaxDesirableRTT = threshold
	}
}

func WithIPQueueTTL(ttl time.Duration) Option {
	return func(i *IPScanner) {
		i.options.IPQueueTTL = ttl
	}
}

func WithConnectionTimeout(timeout time.Duration) Option {
	return func(i *IPScanner) {
		i.options.ConnectionTimeout = timeout
	}
}

func WithHandshakeTimeout(timeout time.Duration) Option {
	return func(i *IPScanner) {
		i.options.HandshakeTimeout = timeout
	}
}

func WithTlsVersion(version uint16) Option {
	return func(i *IPScanner) {
		i.options.TlsVersion = version
	}
}

func WithWarpPrivateKey(privateKey string) Option {
	return func(i *IPScanner) {
		i.options.WarpPrivateKey = privateKey
	}
}

func WithWarpPeerPublicKey(peerPublicKey string) Option {
	return func(i *IPScanner) {
		i.options.WarpPeerPublicKey = peerPublicKey
	}
}

func WithWarpPreSharedKey(presharedKey string) Option {
	return func(i *IPScanner) {
		i.options.WarpPresharedKey = presharedKey
	}
}

func WithConcurrentScanners(scanners int) Option {
	return func(i *IPScanner) {
		i.options.ConcurrentScanners = scanners
	}
}

// WithBucketSize sets the number of IP addresses to sample from each /24 (IPv4) or /120 (IPv6) subnet.
func WithBucketSize(size int) Option {
	return func(i *IPScanner) {
		if size > 0 {
			i.options.BucketSize = size
		}
	}
}

// WithICMPPing enables or disables the initial ICMP ping filter stage.
func WithICMPPing(enable bool) Option {
	return func(i *IPScanner) {
		i.options.IcmpPing = enable
	}
}

// WithTCPPing enables or disables the initial TCP ping filter stage.
func WithTCPPing(enable bool) Option {
	return func(i *IPScanner) {
		i.options.TcpPing = enable
	}
}

// WithICMPPingFilterRTT sets the RTT threshold for the initial ICMP ping filter.
// IPs with an ICMP ping RTT higher than this value will be discarded.
func WithICMPPingFilterRTT(rtt time.Duration) Option {
	return func(i *IPScanner) {
		i.options.ICMPPingFilterRTT = rtt
	}
}

// WithTCPPingFilterRTT sets the RTT threshold for the initial TCP ping filter.
// IPs with a TCP ping RTT higher than this value will be discarded.
func WithTCPPingFilterRTT(rtt time.Duration) Option {
	return func(i *IPScanner) {
		i.options.TCPPingFilterRTT = rtt
	}
}

// WithTCPPingPort sets the port used for the initial TCP ping filter stage.
func WithTCPPingPort(port uint16) Option {
	return func(i *IPScanner) {
		i.options.TCPPingPort = port
	}
}

func WithTestEndpointPorts(hostOrIP string, ports []uint16) Option {
	return func(i *IPScanner) {
		if i.options.TestPortsForIPs == nil {
			i.options.TestPortsForIPs = make(map[netip.Addr][]uint16)
		}

		// Try to parse as a literal IP address (fast path).
		addr, err := netip.ParseAddr(hostOrIP)
		if err == nil {
			i.options.TestPortsForIPs[addr] = ports
			return
		}

		// If it's not a literal IP, assume it's a hostname and try to resolve it.
		i.log.Debug("input for port test is not a literal IP, attempting domain resolution", "host", hostOrIP)
		ctx, cancel := context.WithTimeout(context.Background(), defaultDnsResolveTimeout)
		defer cancel()

		ips, err := net.DefaultResolver.LookupIP(ctx, "ip", hostOrIP)
		if err != nil {
			i.log.Warn("failed to resolve hostname for port test, skipping", "host", hostOrIP, "error", err)
			return
		}

		resolvedCount := 0
		for _, ip := range ips {
			resolvedAddr, ok := netip.AddrFromSlice(ip)
			if !ok {
				continue
			}

			// Add the IP if its family (v4/v6) is enabled in the scanner options.
			if (resolvedAddr.Is4() && i.options.UseIPv4) || (resolvedAddr.Is6() && i.options.UseIPv6) {
				i.options.TestPortsForIPs[resolvedAddr] = ports
				resolvedCount++
			}
		}

		if resolvedCount > 0 {
			i.log.Debug("resolved and added IPs for port testing", "host", hostOrIP, "count", resolvedCount)
		} else {
			i.log.Warn("domain resolved but no IPs matched scanner's IPv4/IPv6 settings for port testing", "host", hostOrIP)
		}
	}
}

func (i *IPScanner) addEndpoint(endpoint string) {
	// Accept comma-separated lists in a single argument (e.g. --endpoints a:1,b:2)
	if strings.Contains(endpoint, ",") {
		for _, part := range strings.Split(endpoint, ",") {
			p := strings.TrimSpace(part)
			if p == "" {
				continue
			}
			i.addEndpoint(p)
		}
		return
	}

	// First, try to parse as a literal IP:Port, which is the common case.
	if addrPort, err := netip.ParseAddrPort(endpoint); err == nil {
		i.options.CustomEndpoints = append(i.options.CustomEndpoints, addrPort)
		return
	}

	// If it's not an IP:Port, try a few fallbacks so users can pass a bare IP or hostname
	// (e.g. "1.2.3.4" or "example.com") and have the scanner use the configured default port.

	// 1) Try parsing as a bare IP (no port). If successful, attach the scanner's default Port.
	if addr, err := netip.ParseAddr(endpoint); err == nil {
		port := i.options.Port
		if port == 0 {
			// Fallback if options were modified; default in NewScanner is 2408.
			port = 2408
		}
		i.options.CustomEndpoints = append(i.options.CustomEndpoints, netip.AddrPortFrom(addr, port))
		i.log.Debug("Added literal IP endpoint using default port", "addr", netip.AddrPortFrom(addr, port))
		return
	}

	// 2) Try host:port (hostname with explicit port). This handles cases like "example.com:2408".
	host, portStr, err := net.SplitHostPort(endpoint)
	if err == nil {
		// Resolve the hostname to IP addresses.
		ctx, cancel := context.WithTimeout(context.Background(), defaultDnsResolveTimeout)
		defer cancel()
		ips, err := net.DefaultResolver.LookupIP(ctx, "ip", host)
		if err != nil {
			i.log.Warn("failed to resolve hostname in custom endpoint", "host", host, "error", err)
			return
		}

		port, err := strconv.ParseUint(portStr, 10, 16)
		if err != nil {
			i.log.Warn("invalid port in custom endpoint", "endpoint", endpoint, "port", portStr, "error", err)
			return
		}
		uint16Port := uint16(port)

		resolvedCount := 0
		for _, ip := range ips {
			addr, ok := netip.AddrFromSlice(ip)
			if !ok {
				continue
			}

			// Add the IP if its family (v4/v6) is enabled in the scanner options.
			if (addr.Is4() && i.options.UseIPv4) || (addr.Is6() && i.options.UseIPv6) {
				i.options.CustomEndpoints = append(i.options.CustomEndpoints, netip.AddrPortFrom(addr, uint16Port))
				resolvedCount++
			}
		}

		if resolvedCount > 0 {
			i.log.Debug("resolved and added IP endpoints from domain", "host", host, "count", resolvedCount)
		} else {
			i.log.Warn("domain resolved but no IPs matched scanner's IPv4/IPv6 settings", "host", host)
		}
		return
	}

	// 3) As a last resort, the input looks like a hostname without a port. Resolve it and
	//    attach the scanner default port to each resolved IP.
	i.log.Debug("input for custom endpoint not in host:port form; attempting resolution with default port", "host", endpoint)
	ctx, cancel := context.WithTimeout(context.Background(), defaultDnsResolveTimeout)
	defer cancel()
	ips, err := net.DefaultResolver.LookupIP(ctx, "ip", endpoint)
	if err != nil {
		i.log.Warn("failed to resolve hostname for custom endpoint", "host", endpoint, "error", err)
		return
	}

	port := i.options.Port
	if port == 0 {
		port = 2408
	}

	resolvedCount := 0
	for _, ip := range ips {
		addr, ok := netip.AddrFromSlice(ip)
		if !ok {
			continue
		}
		if (addr.Is4() && i.options.UseIPv4) || (addr.Is6() && i.options.UseIPv6) {
			i.options.CustomEndpoints = append(i.options.CustomEndpoints, netip.AddrPortFrom(addr, port))
			resolvedCount++
		}
	}
	if resolvedCount > 0 {
		i.log.Debug("resolved and added IP endpoints from domain (no port provided), using default port", "host", endpoint, "count", resolvedCount)
	} else {
		i.log.Warn("domain resolved but no IPs matched scanner's IPv4/IPv6 settings for custom endpoint", "host", endpoint)
	}
}

func WithCustomEndpoints(endpoints []string) Option {
	return func(i *IPScanner) {
		for _, e := range endpoints {
			i.addEndpoint(e)
		}
	}
}

func WithAppendCustomEndpoint(endpoint string) Option {
	return func(i *IPScanner) {
		i.addEndpoint(endpoint)
	}
}

func WithCustomScanPorts(ports string) Option {
	return func(i *IPScanner) {
		portsStr := strings.Split(ports, ",")

		var scanPorts []uint16

		for _, portStr := range portsStr {
			trimmedPortStr := strings.TrimSpace(portStr)

			port, err := strconv.ParseUint(trimmedPortStr, 10, 16)
			if err != nil {
				continue
			}

			scanPorts = append(scanPorts, uint16(port))
		}

		if len(scanPorts) > 0 {
			i.options.DefaultScanPorts = scanPorts
		}
	}
}

// Run executes the strategic scan pipeline. This is a blocking call.
func (i *IPScanner) Run(ctx context.Context) {
	if !i.options.UseIPv4 && !i.options.UseIPv6 {
		i.log.Error("Fatal: both IPv4 and IPv6 are disabled, nothing to do")
		return
	}

	// Apply scan timeout if configured
	if i.options.ScanTimeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, i.options.ScanTimeout)
		defer cancel()
	}

	i.engine = engine.NewScannerEngine(&i.options)
	// Run the engine directly. This makes the call blocking.
	i.engine.Run(ctx)
}

func (i *IPScanner) GetAvailableIPs() []statute.IPInfo {
	if i.engine != nil {
		return i.engine.GetAvailableIPs(false)
	}
	return nil
}

// WithEnableMasqueScanning enables MASQUE endpoint scanning alongside WireGuard
func WithEnableMasqueScanning(enable bool) Option {
	return func(i *IPScanner) {
		i.options.EnableMasqueScanning = enable
		if enable && len(i.options.MasqueScanPorts) == 0 {
			i.options.MasqueScanPorts = i.options.GetDefaultMasquePorts()
		}
	}
}

// WithMasqueOnly scans only MASQUE endpoints (excludes WireGuard)
func WithMasqueOnly(masqueOnly bool) Option {
	return func(i *IPScanner) {
		i.options.MasqueOnly = masqueOnly
		if masqueOnly {
			i.options.EnableMasqueScanning = true
			if len(i.options.MasqueScanPorts) == 0 {
				i.options.MasqueScanPorts = i.options.GetDefaultMasquePorts()
			}
		}
	}
}

// WithMasquePorts sets the ports to scan for MASQUE endpoints
func WithMasquePorts(ports []uint16) Option {
	return func(i *IPScanner) {
		i.options.MasqueScanPorts = ports
	}
}

type IPInfo = statute.IPInfo
