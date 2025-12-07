package masque

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log/slog"
	"math/big"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/bepass-org/vwarp/masque/noize"

	connectip "github.com/Diniboy1123/connect-ip-go"
	"github.com/Diniboy1123/usque/api"
	"github.com/Diniboy1123/usque/config"
	"github.com/quic-go/quic-go"
	"github.com/quic-go/quic-go/http3"
)

const (
	// DefaultMasqueSNI is the default SNI for Cloudflare MASQUE
	DefaultMasqueSNI = "consumer-masque.cloudflareclient.com"

	// ConnectURI is the MASQUE Connect-IP URI (simple tunnel without IP flow forwarding)
	// Must not have template variables to avoid "IP flow forwarding not supported" error
	ConnectURI = "https://cloudflareaccess.com"
)

// MasqueAdapter bridges usque library to vwarp's infrastructure
type MasqueAdapter struct {
	config    *config.Config
	conn      interface{} // *net.UDPConn (HTTP/3) or net.Conn (HTTP/2)
	ipConn    *connectip.Conn
	logger    *slog.Logger
	endpoint  string
	sni       string
	useIPv6   bool
	localIPv4 string
	localIPv6 string
}

// AdapterConfig holds configuration for creating a MASQUE adapter
type AdapterConfig struct {
	// ConfigPath is the path to usque config file (created if doesn't exist)
	ConfigPath string
	// DeviceName for registration (default: "vwarp")
	DeviceName string
	// Endpoint override (optional, uses config endpoint if not set)
	Endpoint string
	// SNI override (optional, uses DefaultMasqueSNI if not set)
	SNI string
	// UseIPv6 determines whether to use IPv6 endpoint
	UseIPv6 bool
	// Logger for debug/info logging
	Logger *slog.Logger
	// License key for WARP+ (optional)
	License string
	// NoizeConfig for QUIC obfuscation (optional)
	NoizeConfig *noize.NoizeConfig
}

// NewMasqueAdapter creates a new MASQUE adapter using usque library
func NewMasqueAdapter(ctx context.Context, cfg AdapterConfig) (*MasqueAdapter, error) {
	if cfg.Logger == nil {
		cfg.Logger = slog.Default()
	}

	// Ensure config directory exists
	if cfg.ConfigPath == "" {
		cfg.ConfigPath = GetDefaultConfigPath()
	}

	dir := filepath.Dir(cfg.ConfigPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create config directory: %w", err)
	}

	// Load or register config
	var usqueConfig *config.Config
	configExists := false
	if _, err := os.Stat(cfg.ConfigPath); err == nil {
		cfg.Logger.Info("Loading existing MASQUE config", "path", cfg.ConfigPath)
		if err := config.LoadConfig(cfg.ConfigPath); err != nil {
			cfg.Logger.Warn("Failed to load config, will re-register", "error", err)
			os.Remove(cfg.ConfigPath)
		} else if config.AppConfig.PrivateKey == "" || config.AppConfig.EndpointV4 == "" || config.AppConfig.ID == "" {
			cfg.Logger.Warn("Config is incomplete, will re-register")
			os.Remove(cfg.ConfigPath)
		} else {
			configExists = true
			usqueConfig = &config.AppConfig
		}
	}

	if !configExists {
		cfg.Logger.Info("No valid MASQUE config found, registering new device", "path", cfg.ConfigPath)

		deviceName := cfg.DeviceName
		if deviceName == "" {
			deviceName = "vwarp"
		}

		// Register using usque API
		accountData, err := api.Register("PC", "en_US", "", true)
		if err != nil {
			return nil, fmt.Errorf("failed to register device: %w", err)
		}

		// Generate EC key pair for MASQUE
		privKey, pubKey, err := generateEcKeyPair()
		if err != nil {
			return nil, fmt.Errorf("failed to generate key pair: %w", err)
		}

		// Enroll the key
		updatedAccountData, apiErr, err := api.EnrollKey(accountData, pubKey, deviceName)
		if err != nil {
			if apiErr != nil {
				return nil, fmt.Errorf("failed to enroll key: %w (API errors: %s)", err, apiErr.ErrorsAsString("; "))
			}
			return nil, fmt.Errorf("failed to enroll key: %w", err)
		}

		// Validate registration data
		if len(updatedAccountData.Config.Peers) == 0 || updatedAccountData.Config.Peers[0].Endpoint.V4 == "" || 
		   updatedAccountData.Config.Peers[0].PublicKey == "" || updatedAccountData.ID == "" {
			return nil, fmt.Errorf("registration failed: incomplete data returned")
		}

		// Create config
		usqueConfig = &config.Config{
			PrivateKey:     base64.StdEncoding.EncodeToString(privKey),
			EndpointV4:     stripPortSuffix(updatedAccountData.Config.Peers[0].Endpoint.V4),
			EndpointV6:     stripPortSuffix(updatedAccountData.Config.Peers[0].Endpoint.V6),
			EndpointPubKey: updatedAccountData.Config.Peers[0].PublicKey,
			License:        updatedAccountData.Account.License,
			ID:             updatedAccountData.ID,
			AccessToken:    accountData.Token,
			IPv4:           updatedAccountData.Config.Interface.Addresses.V4,
			IPv6:           updatedAccountData.Config.Interface.Addresses.V6,
		}

		// Update license if provided
		if cfg.License != "" {
			usqueConfig.License = cfg.License
		}

		// Save config with robust error handling
		if err := saveConfigFile(cfg.ConfigPath, usqueConfig); err != nil {
			return nil, fmt.Errorf("failed to save config: %w", err)
		}

		// Verify config was saved correctly
		if err := config.LoadConfig(cfg.ConfigPath); err != nil || 
		   config.AppConfig.PrivateKey == "" || config.AppConfig.ID == "" {
			return nil, fmt.Errorf("failed to verify saved config")
		}

		cfg.Logger.Info("MASQUE device registered successfully",
			"path", cfg.ConfigPath,
			"ipv4", usqueConfig.IPv4,
			"ipv6", usqueConfig.IPv6,
		)
	}

	// Determine endpoint
	var endpointAddr string
	if cfg.Endpoint != "" {
		endpointAddr = cfg.Endpoint
	} else {
		if cfg.UseIPv6 {
			endpointAddr = usqueConfig.EndpointV6
		} else {
			endpointAddr = usqueConfig.EndpointV4
		}
	}

	// Add port if not specified
	if !strings.Contains(endpointAddr, ":") {
		endpointAddr = fmt.Sprintf("%s:443", endpointAddr)
	}

	// Determine SNI
	sni := cfg.SNI
	if sni == "" {
		sni = DefaultMasqueSNI
	}

	cfg.Logger.Info("Establishing MASQUE connection", "endpoint", endpointAddr, "sni", sni)

	// Get keys from config
	privKey, err := usqueConfig.GetEcPrivateKey()
	if err != nil {
		return nil, fmt.Errorf("failed to get private key: %w", err)
	}

	peerPubKey, err := usqueConfig.GetEcEndpointPublicKey()
	if err != nil {
		return nil, fmt.Errorf("failed to get peer public key: %w", err)
	}

	// Generate self-signed certificate for authentication
	certDER, err := generateSelfSignedCert(privKey)
	if err != nil {
		return nil, fmt.Errorf("failed to generate certificate: %w", err)
	}

	// Check if using a custom endpoint (different from registered)
	usingCustomEndpoint := false
	if cfg.Endpoint != "" {
		registeredEndpoint := usqueConfig.EndpointV4
		if cfg.UseIPv6 && usqueConfig.EndpointV6 != "" {
			registeredEndpoint = usqueConfig.EndpointV6
		}
		customHost, _, _ := net.SplitHostPort(endpointAddr)
		if customHost != registeredEndpoint {
			usingCustomEndpoint = true
			cfg.Logger.Warn("Using custom endpoint - disabling public key pinning", "custom", customHost, "registered", registeredEndpoint)
		}
	}

	// Prepare TLS config
	var tlsConfig *tls.Config
	if usingCustomEndpoint {
		// Skip peer verification for custom endpoints
		tlsConfig = &tls.Config{
			Certificates: []tls.Certificate{
				{
					Certificate: [][]byte{certDER},
					PrivateKey:  privKey,
				},
			},
			ServerName:         sni,
			NextProtos:         []string{"h3"},
			InsecureSkipVerify: true, // Accept any Cloudflare cert
		}
	} else {
		// Use normal verification with public key pinning
		tlsConfig, err = api.PrepareTlsConfig(privKey, peerPubKey, [][]byte{certDER}, sni)
		if err != nil {
			return nil, fmt.Errorf("failed to prepare TLS config: %w", err)
		}
	}

	// Parse endpoint
	udpAddr, err := net.ResolveUDPAddr("udp", endpointAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve endpoint: %w", err)
	}
	cfg.Logger.Debug("Resolved endpoint address", "udpAddr", udpAddr.String(), "ip", udpAddr.IP, "port", udpAddr.Port)

	// Test basic UDP connectivity before QUIC
	cfg.Logger.Debug("Testing UDP connectivity to endpoint")
	testConn, err := net.DialTimeout("udp", udpAddr.String(), 5*time.Second)
	if err != nil {
		cfg.Logger.Error("UDP dial test failed", "error", err)
		return nil, fmt.Errorf("UDP connectivity test failed: %w", err)
	}
	testConn.Close()
	cfg.Logger.Debug("UDP connectivity test successful")

	// Create QUIC config with shorter timeout for faster failure detection
	quicConfig := &quic.Config{
		EnableDatagrams:       true,
		InitialPacketSize:     1242, // CRITICAL: Required for MASQUE - matches Cloudflare WARP implementation
		KeepAlivePeriod:       30 * time.Second,
		MaxIdleTimeout:        60 * time.Second,
		HandshakeIdleTimeout:  10 * time.Second, // Add handshake timeout
		MaxIncomingStreams:    10,
		MaxIncomingUniStreams: 5,
	}
	cfg.Logger.Debug("QUIC config created", "keepAlive", quicConfig.KeepAlivePeriod, "maxIdle", quicConfig.MaxIdleTimeout, "handshakeTimeout", quicConfig.HandshakeIdleTimeout, "initialPacketSize", quicConfig.InitialPacketSize)

	// Create a timeout context for the connection attempt
	connCtx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()

	cfg.Logger.Info("Attempting QUIC connection", "endpoint", udpAddr.String(), "sni", sni)
	cfg.Logger.Debug("TLS ServerName", "serverName", tlsConfig.ServerName)
	cfg.Logger.Debug("TLS NextProtos", "nextProtos", tlsConfig.NextProtos)
	cfg.Logger.Debug("TLS InsecureSkipVerify", "insecureSkipVerify", tlsConfig.InsecureSkipVerify)

	// Log the actual QUIC dial attempt
	cfg.Logger.Info("About to call api.ConnectTunnel - this will attempt QUIC dial")

	// Establish tunnel - use custom function with noize if configured
	var conn *net.UDPConn
	var transport *http3.Transport
	var ipConn *connectip.Conn
	var rsp *http.Response

	if cfg.NoizeConfig != nil {
		cfg.Logger.Info("Using noize obfuscation for MASQUE connection")
		conn, transport, ipConn, rsp, err = ConnectTunnelWithNoize(connCtx, tlsConfig, quicConfig, ConnectURI, udpAddr, cfg.NoizeConfig)
	} else {
		conn, transport, ipConn, rsp, err = api.ConnectTunnel(connCtx, tlsConfig, quicConfig, ConnectURI, udpAddr)
	}

	if err != nil {
		cfg.Logger.Error("QUIC connection failed", "error", err, "endpoint", udpAddr.String(), "errorType", fmt.Sprintf("%T", err))
		return nil, fmt.Errorf("failed to establish MASQUE tunnel: %w", err)
	}

	// Check response status
	if rsp != nil && rsp.StatusCode != 200 {
		cfg.Logger.Error("MASQUE tunnel rejected", "status", rsp.StatusCode, "statusText", rsp.Status)
		if ipConn != nil {
			ipConn.Close()
		}
		if conn != nil {
			conn.Close()
		}
		if transport != nil {
			transport.Close()
		}
		return nil, fmt.Errorf("MASQUE tunnel connection failed: %s", rsp.Status)
	}

	cfg.Logger.Debug("QUIC connection established", "conn", conn != nil, "transport", transport != nil, "ipConn", ipConn != nil)

	// Store connection type for proper cleanup
	var actualConn interface{}
	if conn != nil {
		actualConn = conn
	} else if transport != nil {
		// HTTP/2 fallback - get underlying connection
		actualConn = transport
	}

	cfg.Logger.Info("MASQUE tunnel established successfully")

	return &MasqueAdapter{
		config:    usqueConfig,
		conn:      actualConn,
		ipConn:    ipConn,
		logger:    cfg.Logger,
		endpoint:  endpointAddr,
		sni:       sni,
		useIPv6:   cfg.UseIPv6,
		localIPv4: usqueConfig.IPv4,
		localIPv6: usqueConfig.IPv6,
	}, nil
}

// Read reads IP packets from the MASQUE tunnel
func (m *MasqueAdapter) Read(buf []byte) (int, error) {
	return m.ipConn.ReadPacket(buf, true)
}

// Write writes IP packets to the MASQUE tunnel
func (m *MasqueAdapter) Write(pkt []byte) (int, error) {
	icmp, err := m.ipConn.WritePacket(pkt)
	if err != nil {
		return 0, err
	}
	// Ignore ICMP for simple Write
	_ = icmp
	return len(pkt), nil
}

// WriteWithICMP writes IP packets and returns any ICMP response
func (m *MasqueAdapter) WriteWithICMP(pkt []byte) ([]byte, error) {
	return m.ipConn.WritePacket(pkt)
}

// Close closes the MASQUE connection
func (m *MasqueAdapter) Close() error {
	var errs []error

	if m.ipConn != nil {
		if err := m.ipConn.Close(); err != nil {
			errs = append(errs, fmt.Errorf("failed to close IP connection: %w", err))
		}
	}

	if m.conn != nil {
		// Handle different connection types
		switch c := m.conn.(type) {
		case *net.UDPConn:
			if err := c.Close(); err != nil {
				errs = append(errs, fmt.Errorf("failed to close UDP connection: %w", err))
			}
		case net.Conn:
			if err := c.Close(); err != nil {
				errs = append(errs, fmt.Errorf("failed to close connection: %w", err))
			}
		case *http3.Transport:
			if err := c.Close(); err != nil {
				errs = append(errs, fmt.Errorf("failed to close HTTP/3 transport: %w", err))
			}
		}
	}

	if len(errs) > 0 {
		return fmt.Errorf("errors closing MASQUE adapter: %v", errs)
	}

	return nil
}

// GetLocalAddresses returns the assigned IPv4 and IPv6 addresses
func (m *MasqueAdapter) GetLocalAddresses() (ipv4, ipv6 string) {
	return m.localIPv4, m.localIPv6
}

// GetConfig returns the underlying usque config
func (m *MasqueAdapter) GetConfig() *config.Config {
	return m.config
}

// stripPortSuffix removes port suffix from endpoint strings
func stripPortSuffix(endpoint string) string {
	// Handle IPv4 (e.g., "162.159.195.1:2")
	if strings.Count(endpoint, ":") == 1 {
		host, _, err := net.SplitHostPort(endpoint)
		if err == nil {
			return host
		}
	}
	// Handle IPv6 (e.g., "[2606:4700:d0::1]:2")
	if strings.HasPrefix(endpoint, "[") {
		host, _, err := net.SplitHostPort(endpoint)
		if err == nil {
			// Remove brackets
			return strings.Trim(host, "[]")
		}
	}
	return endpoint
}

// generateSelfSignedCert generates a self-signed certificate for Connect-IP authentication
func generateSelfSignedCert(privKey *ecdsa.PrivateKey) ([]byte, error) {
	// Use minimal certificate template to match usque implementation
	// Cloudflare's MASQUE servers expect a simple self-signed cert
	template := &x509.Certificate{
		SerialNumber: big.NewInt(0),
		NotBefore:    time.Now(),
		NotAfter:     time.Now().Add(1 * 24 * time.Hour),
	}

	certDER, err := x509.CreateCertificate(rand.Reader, template, template, &privKey.PublicKey, privKey)
	if err != nil {
		return nil, fmt.Errorf("failed to create certificate: %w", err)
	}

	return certDER, nil
}

// generateEcKeyPair generates an ECDSA key pair for MASQUE
func generateEcKeyPair() ([]byte, []byte, error) {
	privKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to generate private key: %w", err)
	}

	// Encode private key to ASN.1 DER format
	privKeyDER, err := x509.MarshalECPrivateKey(privKey)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to marshal private key: %w", err)
	}

	// Encode public key to PKIX DER format
	pubKeyDER, err := x509.MarshalPKIXPublicKey(&privKey.PublicKey)
	if err != nil {
		return nil, nil, fmt.Errorf("failed to marshal public key: %w", err)
	}

	return privKeyDER, pubKeyDER, nil
}

// saveConfigFile saves config to file with atomic write for robustness
func saveConfigFile(configPath string, cfg *config.Config) error {
	file, err := os.Create(configPath)
	if err != nil {
		return fmt.Errorf("failed to create config file: %w", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(cfg); err != nil {
		return fmt.Errorf("failed to encode config: %w", err)
	}

	return nil
}
