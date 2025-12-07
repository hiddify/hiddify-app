package noize

import (
	"fmt"
	"net"
	"sync"
	"time"
)

// NoizeUDPConn wraps a UDP connection with obfuscation
type NoizeUDPConn struct {
	*net.UDPConn
	noize   *Noize
	mu      sync.RWMutex
	enabled bool
	addrMap map[string]*net.UDPAddr
}

// WrapUDPConn wraps a UDP connection with noize obfuscation
func WrapUDPConn(conn *net.UDPConn, config *NoizeConfig) *NoizeUDPConn {
	noize := New(config)
	wrapped := &NoizeUDPConn{
		UDPConn: conn,
		noize:   noize,
		enabled: true,
		addrMap: make(map[string]*net.UDPAddr),
	}
	noize.WrapConn(conn)
	return wrapped
}

// WriteToUDP writes obfuscated data to UDP
func (c *NoizeUDPConn) WriteToUDP(b []byte, addr *net.UDPAddr) (int, error) {
	if !c.enabled || c.noize == nil {
		return c.UDPConn.WriteToUDP(b, addr)
	}

	config := c.noize.config
	if config.Jc == 0 && config.JcBeforeHS == 0 && config.JcAfterI1 == 0 &&
		config.JcDuringHS == 0 && config.JcAfterHS == 0 && config.PaddingMax == 0 &&
		!config.FragmentInitial && config.I1 == "" && config.I2 == "" {
		if c.noize.debugPadding {
			fmt.Printf("NOIZE_DEBUG: All obfuscation disabled, bypassing - packet size: %d\n", len(b))
		}
		return c.UDPConn.WriteToUDP(b, addr)
	}

	if c.noize.debugPadding {
		fmt.Printf("NOIZE_DEBUG: WriteToUDP called - packet size: %d, addr: %s\n", len(b), addr.String())
	}

	// Obfuscate the packet
	obfuscated, err := c.noize.ObfuscateWrite(b, addr)
	if err != nil {
		if c.noize.debugPadding {
			fmt.Printf("NOIZE_DEBUG: ObfuscateWrite error: %v\n", err)
		}
		return 0, err
	}

	// Debug: Log result
	if c.noize.debugPadding {
		fmt.Printf("NOIZE_DEBUG: Packet obfuscated - original: %d bytes, final: %d bytes\n", len(b), len(obfuscated))
	}

	// Write obfuscated packet
	return c.UDPConn.WriteToUDP(obfuscated, addr)
}

// WriteTo implements the WriterTo interface (used by QUIC)
func (c *NoizeUDPConn) WriteTo(b []byte, addr net.Addr) (int, error) {
	udpAddr, ok := addr.(*net.UDPAddr)
	if !ok {
		return c.UDPConn.WriteTo(b, addr)
	}
	return c.WriteToUDP(b, udpAddr)
}

// ReadFrom implements the ReaderFrom interface (used by QUIC)
func (c *NoizeUDPConn) ReadFrom(b []byte) (int, net.Addr, error) {
	return c.UDPConn.ReadFrom(b)
}

// ReadFromUDP reads from UDP (no de-obfuscation needed)
func (c *NoizeUDPConn) ReadFromUDP(b []byte) (int, *net.UDPAddr, error) {
	return c.UDPConn.ReadFromUDP(b)
}

// Write writes obfuscated data (requires prior Connect or stored addr)
func (c *NoizeUDPConn) Write(b []byte) (int, error) {
	if !c.enabled || c.noize == nil {
		return c.UDPConn.Write(b)
	}

	// Get remote address - try stored address first for better WiFi compatibility
	var remoteAddr net.Addr
	c.mu.RLock()
	if len(c.addrMap) > 0 {
		for _, addr := range c.addrMap {
			remoteAddr = addr
			break
		}
	}
	c.mu.RUnlock()

	// Fallback to connection's remote address
	if remoteAddr == nil {
		remoteAddr = c.UDPConn.RemoteAddr()
	}

	if remoteAddr == nil {
		return c.UDPConn.Write(b)
	}

	udpAddr, ok := remoteAddr.(*net.UDPAddr)
	if !ok {
		return c.UDPConn.Write(b)
	}

	return c.WriteToUDP(b, udpAddr)
}

// Enable enables obfuscation
func (c *NoizeUDPConn) Enable() {
	c.mu.Lock()
	c.enabled = true
	c.mu.Unlock()
}

// Disable disables obfuscation
func (c *NoizeUDPConn) Disable() {
	c.mu.Lock()
	c.enabled = false
	c.mu.Unlock()
}

// SetConfig updates the noize configuration
func (c *NoizeUDPConn) SetConfig(config *NoizeConfig) {
	c.mu.Lock()
	c.noize = New(config)
	c.noize.WrapConn(c.UDPConn)
	c.mu.Unlock()
}

// StoreAddr stores an address for later use
func (c *NoizeUDPConn) StoreAddr(key string, addr *net.UDPAddr) {
	c.mu.Lock()
	c.addrMap[key] = addr
	c.mu.Unlock()
}

// GetConfig returns current configuration
func (c *NoizeUDPConn) GetConfig() *NoizeConfig {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.noize.config
}

func (c *NoizeUDPConn) EnableDebugPadding() {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.noize != nil {
		c.noize.EnableDebugPadding()
	}
}

func (c *NoizeUDPConn) DisableDebugPadding() {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.noize != nil {
		c.noize.DisableDebugPadding()
	}
}

// PresetConfigs provides preset obfuscation configurations

// LightObfuscationConfig - minimal obfuscation with junk packets to bypass DPI
func LightObfuscationConfig() *NoizeConfig {
	return &NoizeConfig{
		I1:               "<b 474554202f20485454502f312e31><r 8>", // HTTP GET signature
		FragmentInitial:  false,                                   // Don't fragment to avoid complexity
		PaddingMin:       0,                                       // Small padding to change packet size
		PaddingMax:       0,                                       // Variable padding
		RandomPadding:    false,
		Jc:               8,                    // Total junk packets
		JcBeforeHS:       2,                    // Junk before handshake
		JcAfterI1:        1,                    // Junk after signature
		JcDuringHS:       2,                    // Junk during handshake
		JcAfterHS:        3,                    // Junk after handshake
		Jmin:             40,                   // Minimum junk size (realistic)
		Jmax:             120,                  // Maximum junk size
		JunkInterval:     3 * time.Millisecond, // Small delay between junk
		JunkRandom:       true,
		HandshakeDelay:   5 * time.Millisecond, // Small delay before handshake
		MimicProtocol:    "",                   // Mimic HTTPS traffic
		RandomDelay:      true,
		DelayMin:         1 * time.Millisecond,
		DelayMax:         5 * time.Millisecond,
		SNIFragmentation: true, // Keep simple for now
		UseTimestamp:     false,
		UseNonce:         true,  // Add some randomness
		RandomizeInitial: true,  // Randomize initial packet
		AllowZeroSize:    false, // Don't allow zero size
	}
}

// FirewallBypassConfig - based on working GFW config but lighter
func FirewallBypassConfig() *NoizeConfig {
	return &NoizeConfig{
		// Mimic HTTP/3 QUIC with realistic patterns (same as GFW)
		I1:              "<b 0d0a0d0a><t><r 24>",
		I2:              "<r 48>",
		FragmentSize:    1200,
		FragmentInitial: false,
		FragmentDelay:   2 * time.Millisecond,
		PaddingMin:      2,
		PaddingMax:      6,
		RandomPadding:   false,
		Jc:              6,
		Jmin:            48,
		Jmax:            190,
		JcBeforeHS:      2,
		JcAfterI1:       2,
		JcDuringHS:      2,
		JcAfterHS:       2,
		JunkInterval:    4 * time.Millisecond,
		JunkRandom:      true,
		MimicProtocol:   "",
		HandshakeDelay:  5 * time.Millisecond,
		RandomDelay:     true,
		DelayMin:        2 * time.Millisecond,
		DelayMax:        12 * time.Millisecond,

		SNIFragmentation: false,
		SNIFragment:      12,
		UseTimestamp:     false,
		UseNonce:         true,
		RandomizeInitial: false,
		DuplicatePackets: false,
		FakeLoss:         0.01, // 1% fake loss
	}
}

// MediumObfuscationConfig - balanced obfuscation
func MediumObfuscationConfig() *NoizeConfig {
	return DefaultConfig()
}

// HeavyObfuscationConfig - maximum obfuscation, higher overhead
func HeavyObfuscationConfig() *NoizeConfig {
	return &NoizeConfig{
		I1:               "<b 0d0a0d0a><t><r 32>",
		I2:               "<b 474554202f20485454502f312e31><r 16>",
		I3:               "<r 64>",
		FragmentSize:     1280,
		FragmentInitial:  true,
		FragmentDelay:    3 * time.Millisecond,
		PaddingMin:       3,
		PaddingMax:       12,
		RandomPadding:    true,
		Jc:               10,
		Jmin:             128,
		Jmax:             512,
		JcBeforeHS:       3,
		JcAfterI1:        2,
		JcDuringHS:       2,
		JcAfterHS:        3,
		JunkInterval:     8 * time.Millisecond,
		JunkRandom:       true,
		MimicProtocol:    "",
		HandshakeDelay:   20 * time.Millisecond,
		RandomDelay:      true,
		DelayMin:         2 * time.Millisecond,
		DelayMax:         15 * time.Millisecond,
		SNIFragmentation: true,
		SNIFragment:      16,
		UseTimestamp:     true,
		UseNonce:         true,
		RandomizeInitial: true,
	}
}

// StealthObfuscationConfig - looks like regular HTTPS traffic
func StealthObfuscationConfig() *NoizeConfig {
	return &NoizeConfig{
		I1:               "<b 160301><r 2><b 0100>", // TLS ClientHello start
		MimicProtocol:    "",
		PaddingMin:       16,
		PaddingMax:       18,
		RandomPadding:    false,
		Jc:               3,
		Jmin:             40,
		Jmax:             200,
		JcBeforeHS:       1,
		JcAfterI1:        1,
		JcAfterHS:        1,
		JunkInterval:     10 * time.Millisecond,
		HandshakeDelay:   15 * time.Millisecond,
		RandomDelay:      true,
		DelayMin:         5 * time.Millisecond,
		DelayMax:         25 * time.Millisecond,
		UseTimestamp:     false, // Don't use obvious timestamps
		RandomizeInitial: false,
	}
}

// GFWBypassConfig - specifically designed to bypass Great Firewall
func GFWBypassConfig() *NoizeConfig {
	return &NoizeConfig{
		I1:              "<b 0d0a0d0a><t><r 24>",
		I2:              "<r 48>",
		FragmentSize:    1200,
		FragmentInitial: false,
		FragmentDelay:   3 * time.Millisecond,
		PaddingMin:      8,
		PaddingMax:      12,
		RandomPadding:   true,
		Jc:              8,
		Jmin:            64,
		Jmax:            384,
		JcBeforeHS:      3,
		JcAfterI1:       2,
		JcDuringHS:      2,
		JcAfterHS:       1,
		JunkInterval:    3 * time.Millisecond,
		JunkRandom:      true,
		MimicProtocol:   "",

		HandshakeDelay:   25 * time.Millisecond,
		RandomDelay:      true,
		DelayMin:         1 * time.Millisecond,
		DelayMax:         20 * time.Millisecond,
		SNIFragmentation: true,
		SNIFragment:      8,
		UseTimestamp:     true,
		UseNonce:         true,
		RandomizeInitial: true,
		DuplicatePackets: false, // Avoid triggering DPI
		FakeLoss:         0.02,  // 2% fake loss to appear natural
	}
}

// NoObfuscationConfig - disable all obfuscation
func NoObfuscationConfig() *NoizeConfig {
	return &NoizeConfig{
		Jc:              0,
		FragmentInitial: false,
		PaddingMin:      0,
		PaddingMax:      0,
		HandshakeDelay:  0,
	}
}

// MinimalObfuscationConfig - very light obfuscation, least likely to break handshake
func MinimalObfuscationConfig() *NoizeConfig {
	return &NoizeConfig{
		// Minimal obfuscation - just a few junk packets after handshake
		PaddingMin:      0,
		PaddingMax:      0,
		RandomPadding:   false,
		Jc:              12, // Very few junk packets
		JcBeforeHS:      4,  // No junk before handshake
		JcAfterI1:       4,  // No junk after I1
		JcDuringHS:      4,  // No junk during handshake
		JcAfterHS:       3,  // Only after handshake
		Jmin:            0,
		Jmax:            0,
		FragmentInitial: false, // Don't fragment
		HandshakeDelay:  0,     // No delay
		JunkInterval:    5 * time.Millisecond,
		AllowZeroSize:   true,
	}
}
