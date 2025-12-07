package statute

import (
	"context"
	"log/slog"
	"math/rand"
	"net"
	"net/http"
	"net/netip"
	"time"
)

type TIPQueueChangeCallback func(ips []IPInfo)

type (
	TDialerFunc     func(ctx context.Context, network, addr string) (net.Conn, error)
	THTTPClientFunc func(rawDialer TDialerFunc, tlsDialer TDialerFunc, targetAddr ...string) *http.Client
)

type IPInfo struct {
	AddrPort  netip.AddrPort
	RTT       time.Duration
	CreatedAt time.Time
}

type ScannerOptions struct {
	UseIPv4            bool
	UseIPv6            bool
	CidrList           []netip.Prefix // CIDR ranges to scan
	CustomEndpoints    []netip.AddrPort
	TestPortsForIPs    map[netip.Addr][]uint16
	Logger             *slog.Logger
	InsecureSkipVerify bool
	RawDialerFunc      TDialerFunc
	TLSDialerFunc      TDialerFunc
	HttpClientFunc     THTTPClientFunc
	UseHTTP2           bool
	DisableCompression bool
	HTTPPath           string
	Referrer           string
	UserAgent          string
	Hostname           string
	WarpPrivateKey     string
	WarpPeerPublicKey  string
	WarpPresharedKey   string
	Port               uint16
	DefaultScanPorts   []uint16
	// MASQUE-specific options
	EnableMasqueScanning  bool
	MasqueOnly            bool
	MasqueScanPorts       []uint16
	IcmpPing              bool
	TcpPing               bool
	TCPPingPort           uint16
	BucketSize            int // Number of IPs to select from each /24 subnet.
	ICMPPingFilterRTT     time.Duration
	TCPPingFilterRTT      time.Duration
	IPQueueSize           int
	IPQueueTTL            time.Duration
	MaxDesirableRTT       time.Duration
	IPQueueChangeCallback TIPQueueChangeCallback
	ConnectionTimeout     time.Duration
	HandshakeTimeout      time.Duration
	TlsVersion            uint16
	ConcurrentScanners    int
	ScanTimeout           time.Duration
	StopOnFirstGoodIPs    int
}

func (e *ScannerOptions) GetRandomWarpPort() uint16 {
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	return e.DefaultScanPorts[rng.Intn(len(e.DefaultScanPorts))]
}

func (e *ScannerOptions) GetRandomMasquePort() uint16 {
	if len(e.MasqueScanPorts) == 0 {
		return 443 // Default MASQUE port
	}
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	return e.MasqueScanPorts[rng.Intn(len(e.MasqueScanPorts))]
}

func (e *ScannerOptions) GetDefaultMasquePorts() []uint16 {
	return []uint16{443, 8443, 2053, 2083, 2087, 2096} // Common HTTPS/QUIC ports
}
