package masque

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"log/slog"
	"math/rand"
	"net"
	"sort"
	"sync"
	"sync/atomic"
	"time"
	// "github.com/Diniboy1123/usque/api" // Temporarily disabled - API needs update
)

// ScanResult represents the result of scanning a single endpoint
type ScanResult struct {
	Endpoint    string
	IP          net.IP
	Port        int
	Success     bool
	Latency     time.Duration
	Error       error
	PingTime    time.Duration
	HandshakeOK bool
}

// ScannerConfig holds configuration for the MASQUE endpoint scanner
type ScannerConfig struct {
	// IPv4Ranges are CIDR ranges to scan for IPv4 endpoints
	IPv4Ranges []string
	// IPv6Ranges are CIDR ranges to scan for IPv6 endpoints
	IPv6Ranges []string
	// CustomEndpoints are specific endpoints to test
	CustomEndpoints []string
	// MaxEndpoints is the maximum number of endpoints to try
	MaxEndpoints int
	// ScanTimeout is the timeout for each endpoint scan attempt
	ScanTimeout time.Duration
	// Workers is the number of concurrent scanning workers
	Workers int
	// PingEnabled enables TCP ping before connection attempt
	PingEnabled bool
	// PingTimeout is the timeout for ping attempts
	PingTimeout time.Duration
	// Ordered scans endpoints in CIDR order (no shuffle)
	Ordered bool
	// TunnelFailLimit is the number of tunnel failures before skipping endpoint
	TunnelFailLimit int
	// UseIPv6 prefers IPv6 endpoints
	UseIPv6 bool
	// Ports to use for scanning (default [443])
	Ports []int
	// Logger for scan output
	Logger *slog.Logger
	// PrivKey and PeerPubKey for connection testing
	PrivKey    *ecdsa.PrivateKey
	PeerPubKey *ecdsa.PublicKey
	// SNI for connection
	SNI string
	// EarlyExit stops scanning after first successful endpoint
	EarlyExit bool
	// VerboseChild prints connection logs during scan
	VerboseChild bool
}

// DefaultIPv4Ranges returns default Cloudflare MASQUE IPv4 ranges
func DefaultIPv4Ranges() []string {
	return []string{
		"162.159.192.0/24",
		"162.159.193.0/24",
		"162.159.195.0/24",
		"162.159.197.0/24",
		"162.159.198.0/24", // User tested working endpoint
		"162.159.199.0/24",
		"162.159.200.0/24",
		"162.159.201.0/24",
		"162.159.202.0/24",
		"162.159.203.0/24",
		"162.159.204.0/24",
	}
}

// DefaultIPv6Ranges returns default Cloudflare MASQUE IPv6 ranges
func DefaultIPv6Ranges() []string {
	return []string{
		"2606:4700:d0::/48",
		"2606:4700:d1::/48",
		"2606:4700:103::1/128", // User provided working endpoint
	}
}

// Scanner is a professional endpoint scanner for MASQUE
type Scanner struct {
	config    ScannerConfig
	results   []ScanResult
	resultsMu sync.Mutex
	logger    *slog.Logger
	stopChan  chan struct{}
	stopped   atomic.Bool
}

// NewScanner creates a new MASQUE endpoint scanner
func NewScanner(config ScannerConfig) *Scanner {
	if config.MaxEndpoints <= 0 {
		config.MaxEndpoints = 30
	}
	if config.ScanTimeout == 0 {
		config.ScanTimeout = 5 * time.Second
	}
	if config.Workers <= 0 {
		config.Workers = 10
	}
	if config.PingTimeout == 0 {
		config.PingTimeout = 2 * time.Second
	}
	if config.TunnelFailLimit <= 0 {
		config.TunnelFailLimit = 2
	}
	if len(config.Ports) == 0 {
		// Default Cloudflare MASQUE ports
		config.Ports = []int{443, 500, 1701, 4500, 4443, 8443, 8095}
	}
	if config.Logger == nil {
		config.Logger = slog.Default()
	}
	if config.SNI == "" {
		config.SNI = DefaultMasqueSNI
	}

	return &Scanner{
		config:   config,
		logger:   config.Logger,
		stopChan: make(chan struct{}),
	}
}

// generateCandidates generates IP candidates from CIDR ranges and custom endpoints
func (s *Scanner) generateCandidates() []string {
	var candidates []string

	// Add custom endpoints first
	candidates = append(candidates, s.config.CustomEndpoints...)

	// Determine which ranges to use
	ranges := s.config.IPv4Ranges
	if s.config.UseIPv6 && len(s.config.IPv6Ranges) > 0 {
		ranges = s.config.IPv6Ranges
	}

	// Default ranges if none specified and no custom endpoints
	if len(ranges) == 0 && len(candidates) == 0 {
		if s.config.UseIPv6 {
			ranges = DefaultIPv6Ranges()
		} else {
			ranges = DefaultIPv4Ranges()
		}
	}

	// Expand CIDR ranges with multiple ports
	for _, cidr := range ranges {
		ips := expandCIDR(cidr, s.config.MaxEndpoints-len(candidates))
		for _, ip := range ips {
			// Try each port for this IP
			for _, port := range s.config.Ports {
				endpoint := net.JoinHostPort(ip.String(), fmt.Sprintf("%d", port))
				// IPv6 needs brackets
				if ip.To4() == nil {
					endpoint = fmt.Sprintf("[%s]:%d", ip.String(), port)
				}
				candidates = append(candidates, endpoint)
				if len(candidates) >= s.config.MaxEndpoints {
					goto done
				}
			}
		}
	}
done:

	// Shuffle for random selection unless ordered
	if !s.config.Ordered && len(candidates) > len(s.config.CustomEndpoints) {
		// Only shuffle the non-custom endpoints
		customCount := len(s.config.CustomEndpoints)
		shuffleable := candidates[customCount:]
		rand.Shuffle(len(shuffleable), func(i, j int) {
			shuffleable[i], shuffleable[j] = shuffleable[j], shuffleable[i]
		})
	}

	// Limit to MaxEndpoints
	if len(candidates) > s.config.MaxEndpoints {
		candidates = candidates[:s.config.MaxEndpoints]
	}

	return candidates
}

// expandCIDR expands a CIDR range to individual IPs, up to maxIPs
func expandCIDR(cidr string, maxIPs int) []net.IP {
	ip, ipnet, err := net.ParseCIDR(cidr)
	if err != nil {
		return nil
	}

	var ips []net.IP
	for ip := ip.Mask(ipnet.Mask); ipnet.Contains(ip); incIP(ip) {
		// Skip network and broadcast addresses
		if !isNetworkOrBroadcast(ip, ipnet) {
			ips = append(ips, copyIP(ip))
			if len(ips) >= maxIPs {
				break
			}
		}
	}

	return ips
}

// incIP increments an IP address
func incIP(ip net.IP) {
	for j := len(ip) - 1; j >= 0; j-- {
		ip[j]++
		if ip[j] > 0 {
			break
		}
	}
}

// copyIP creates a copy of an IP address
func copyIP(ip net.IP) net.IP {
	dup := make(net.IP, len(ip))
	copy(dup, ip)
	return dup
}

// isNetworkOrBroadcast checks if an IP is a network or broadcast address
func isNetworkOrBroadcast(ip net.IP, ipnet *net.IPNet) bool {
	// Network address
	if ip.Equal(ipnet.IP) {
		return true
	}

	// Broadcast address (for IPv4)
	if ip.To4() != nil {
		broadcast := make(net.IP, len(ip))
		copy(broadcast, ipnet.IP)
		for i := range broadcast {
			broadcast[i] |= ^ipnet.Mask[i]
		}
		if ip.Equal(broadcast) {
			return true
		}
	}

	return false
}

// pingEndpoint performs a TCP ping to test connectivity
func (s *Scanner) pingEndpoint(ctx context.Context, endpoint string) (time.Duration, error) {
	start := time.Now()

	dialer := &net.Dialer{
		Timeout: s.config.PingTimeout,
	}

	conn, err := dialer.DialContext(ctx, "tcp", endpoint)
	if err != nil {
		return 0, err
	}
	conn.Close()

	return time.Since(start), nil
}

// testEndpoint tests a single endpoint for MASQUE connectivity
func (s *Scanner) testEndpoint(ctx context.Context, endpoint string) ScanResult {
	// Parse endpoint to get IP and port
	host, portStr, err := net.SplitHostPort(endpoint)
	if err != nil {
		return ScanResult{
			Endpoint: endpoint,
			Error:    fmt.Errorf("invalid endpoint format: %w", err),
		}
	}

	ip := net.ParseIP(host)
	if ip == nil {
		return ScanResult{
			Endpoint: endpoint,
			Error:    fmt.Errorf("invalid IP address: %s", host),
		}
	}

	var port int
	fmt.Sscanf(portStr, "%d", &port)

	result := ScanResult{
		Endpoint: endpoint,
		IP:       ip,
		Port:     port,
	}

	// Optional TCP ping test
	if s.config.PingEnabled {
		pingTime, err := s.pingEndpoint(ctx, endpoint)
		result.PingTime = pingTime
		if err != nil {
			if s.config.VerboseChild {
				s.logger.Debug("ping failed", "endpoint", endpoint, "error", err)
			}
			result.Error = fmt.Errorf("ping failed: %w", err)
			return result
		}
	}

	// Test MASQUE connection
	start := time.Now()

	// Scanner doesn't use noize obfuscation (for speed)
	// Use placeholder IPs since scanner only tests connection, not data transfer
	// TODO: Fix this - CreateMasqueClient function doesn't exist in current usque API
	// The MASQUE scanner is temporarily disabled until the API is updated
	_ = start // prevent unused warning

	result.Latency = time.Since(start)
	result.Error = fmt.Errorf("MASQUE scanner is temporarily disabled - API needs update")
	result.Success = false

	if s.config.VerboseChild {
		s.logger.Debug("MASQUE scanner disabled", "endpoint", endpoint)
	}

	return result
}

// Scan performs the endpoint scan and returns the best endpoint
func (s *Scanner) Scan(ctx context.Context) (*ScanResult, error) {
	candidates := s.generateCandidates()
	if len(candidates) == 0 {
		return nil, fmt.Errorf("no candidates generated from ranges")
	}

	s.logger.Info("Starting MASQUE endpoint scan",
		"candidates", len(candidates),
		"workers", s.config.Workers,
		"timeout", s.config.ScanTimeout,
		"ping", s.config.PingEnabled,
	)

	// Create work queue
	jobs := make(chan string, len(candidates))
	results := make(chan ScanResult, s.config.Workers)

	// Track statistics
	var tested, successful, failed atomic.Int32

	// Start workers
	var wg sync.WaitGroup
	for i := 0; i < s.config.Workers; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			for {
				select {
				case endpoint, ok := <-jobs:
					if !ok {
						return
					}

					tested.Add(1)
					result := s.testEndpoint(ctx, endpoint)

					select {
					case results <- result:
					case <-s.stopChan:
						return
					case <-ctx.Done():
						return
					}

				case <-s.stopChan:
					return
				case <-ctx.Done():
					return
				}
			}
		}(i)
	}

	// Send jobs
	go func() {
		for _, endpoint := range candidates {
			select {
			case jobs <- endpoint:
			case <-s.stopChan:
				break
			case <-ctx.Done():
				break
			}
		}
		close(jobs)
	}()

	// Collect results
	go func() {
		wg.Wait()
		close(results)
	}()

	// Process results
	var successfulResults []ScanResult
	foundWorking := false

	for result := range results {
		s.resultsMu.Lock()
		s.results = append(s.results, result)
		s.resultsMu.Unlock()

		if result.Success {
			successful.Add(1)
			successfulResults = append(successfulResults, result)

			s.logger.Info("✓ Working endpoint found",
				"endpoint", result.Endpoint,
				"latency", result.Latency,
				"ping", result.PingTime,
				"tested", tested.Load(),
			)

			// Early exit if configured
			if s.config.EarlyExit && !foundWorking {
				foundWorking = true
				s.logger.Info("Early exit enabled, stopping scan")
				close(s.stopChan)
			}
		} else {
			failed.Add(1)
			if s.config.VerboseChild {
				s.logger.Debug("✗ Endpoint failed",
					"endpoint", result.Endpoint,
					"error", result.Error,
					"latency", result.Latency,
				)
			}
		}
	}

	totalTested := tested.Load()
	totalSuccess := successful.Load()
	totalFailed := failed.Load()

	s.logger.Info("Scan complete",
		"successful", totalSuccess,
		"failed", totalFailed,
		"tested", totalTested,
		"total_candidates", len(candidates),
	)

	if len(successfulResults) == 0 {
		return nil, fmt.Errorf("no viable endpoint found (tried %d)", totalTested)
	}

	// Sort by latency and return best
	sort.Slice(successfulResults, func(i, j int) bool {
		// Prefer endpoints with successful ping if ping is enabled
		if s.config.PingEnabled {
			if successfulResults[i].PingTime > 0 && successfulResults[j].PingTime == 0 {
				return true
			}
			if successfulResults[i].PingTime == 0 && successfulResults[j].PingTime > 0 {
				return false
			}
		}
		// Sort by connection latency
		return successfulResults[i].Latency < successfulResults[j].Latency
	})

	best := successfulResults[0]
	s.logger.Info("Best endpoint selected",
		"endpoint", best.Endpoint,
		"latency", best.Latency,
		"ping", best.PingTime,
	)

	return &best, nil
}

// Stop stops an ongoing scan
func (s *Scanner) Stop() {
	if !s.stopped.Swap(true) {
		close(s.stopChan)
	}
}

// GetResults returns all scan results
func (s *Scanner) GetResults() []ScanResult {
	s.resultsMu.Lock()
	defer s.resultsMu.Unlock()
	return append([]ScanResult{}, s.results...)
}

// GetSuccessfulResults returns only successful scan results sorted by latency
func (s *Scanner) GetSuccessfulResults() []ScanResult {
	s.resultsMu.Lock()
	defer s.resultsMu.Unlock()

	var successful []ScanResult
	for _, r := range s.results {
		if r.Success {
			successful = append(successful, r)
		}
	}

	sort.Slice(successful, func(i, j int) bool {
		return successful[i].Latency < successful[j].Latency
	})

	return successful
}
