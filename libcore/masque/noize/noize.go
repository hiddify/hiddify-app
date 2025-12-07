package noize

import (
	"crypto/rand"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"fmt"
	mathrand "math/rand"
	"net"
	"os"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

var rng = mathrand.New(mathrand.NewSource(time.Now().UnixNano()))

// NoizeConfig holds MASQUE QUIC obfuscation parameters
type NoizeConfig struct {
	// === Signature Packets (Protocol Imitation) ===
	I1 string `json:"i1,omitempty"` // Main signature packet (mimics legitimate protocols)
	I2 string `json:"i2,omitempty"` // Secondary signature packet
	I3 string `json:"i3,omitempty"` // Tertiary signature packet
	I4 string `json:"i4,omitempty"` // Additional signature packet
	I5 string `json:"i5,omitempty"` // Additional signature packet

	// === QUIC Packet Fragmentation ===
	FragmentSize    int           `json:"fragment_size,omitempty"`    // Fragment QUIC packets to this size (0 = no fragmentation)
	FragmentInitial bool          `json:"fragment_initial,omitempty"` // Fragment QUIC Initial packets specifically
	FragmentDelay   time.Duration // Delay between fragments

	// === Padding & Obfuscation ===
	PaddingMin    int  // Minimum padding bytes per packet
	PaddingMax    int  // Maximum padding bytes per packet
	RandomPadding bool // Use random padding size

	// === Junk Packet Configuration ===
	Jc   int // Total number of junk packets (0-20)
	Jmin int // Minimum junk packet size
	Jmax int // Maximum junk packet size

	// === Advanced Junk Timing ===
	JcBeforeHS   int           // Junk packets before QUIC handshake
	JcAfterI1    int           // Junk packets after I1 signature
	JcDuringHS   int           // Junk packets during handshake
	JcAfterHS    int           // Junk packets after handshake complete
	JunkInterval time.Duration // Interval between junk packets
	JunkRandom   bool          // Randomize junk timing

	// === Protocol Mimicry ===
	MimicProtocol string // Protocol to mimic: "dns", "https", "h3", "dtls", "stun"
	CustomWrapper bool   // Use custom protocol wrapper

	// === Timing Obfuscation ===
	HandshakeDelay time.Duration // Delay before actual QUIC handshake
	PacketDelay    time.Duration // Delay between packets
	RandomDelay    bool          // Randomize packet delays
	DelayMin       time.Duration // Minimum random delay
	DelayMax       time.Duration // Maximum random delay

	// === SNI & ALPN Manipulation ===
	SNIFragmentation bool     // Fragment SNI in ClientHello
	SNIFragment      int      // SNI fragment size
	FakeALPN         []string // Fake ALPN protocols to advertise

	// === Advanced Features ===
	ReversedOrder    bool // Send packets in reversed order
	DuplicatePackets bool // Duplicate certain packets
	AllowZeroSize    bool // Allow zero-size junk packets

	// === Anti-Replay ===
	UseTimestamp bool // Add timestamp to signature packets
	UseNonce     bool // Add random nonce

	// === Connection Fingerprinting Mitigation ===
	RandomizeInitial bool    // Randomize Initial packet structure
	FakeLoss         float32 // Simulate packet loss (0.0-1.0)
}

// Noize handles MASQUE QUIC packet obfuscation
type Noize struct {
	config       *NoizeConfig
	conn         *net.UDPConn
	mu           sync.RWMutex
	lastSent     map[string]time.Time
	hsState      map[string]*handshakeState
	seqNum       uint32
	debugPadding bool // Debug flag for padding operations
}

type handshakeState struct {
	preSent     bool
	duringSent  bool
	postSent    bool
	initialSeen bool
}

// New creates a new Noize obfuscator
func New(config *NoizeConfig) *Noize {
	if config == nil {
		config = DefaultConfig()
	}
	return &Noize{
		config:   config,
		lastSent: make(map[string]time.Time),
		hsState:  make(map[string]*handshakeState),
	}
}

// DefaultConfig returns default obfuscation configuration
func DefaultConfig() *NoizeConfig {
	return &NoizeConfig{
		// Mimic HTTPS/HTTP3 initial connection
		I1: "<b 0d0a0d0a><t><r 16>",

		FragmentSize:    512,
		FragmentInitial: true,
		FragmentDelay:   2 * time.Millisecond,

		PaddingMin:    16,
		PaddingMax:    64,
		RandomPadding: true,

		Jc:   5,
		Jmin: 64,
		Jmax: 256,

		JcBeforeHS:   2,
		JcAfterI1:    1,
		JcDuringHS:   1,
		JcAfterHS:    1,
		JunkInterval: 5 * time.Millisecond,
		JunkRandom:   true,

		MimicProtocol: "h3",

		HandshakeDelay: 10 * time.Millisecond,
		RandomDelay:    true,
		DelayMin:       1 * time.Millisecond,
		DelayMax:       10 * time.Millisecond,

		SNIFragmentation: true,
		SNIFragment:      32,

		UseTimestamp: true,
		UseNonce:     true,

		RandomizeInitial: true,
		AllowZeroSize:    false,
	}
}

// WrapConn wraps a UDP connection with noize obfuscation
func (n *Noize) WrapConn(conn *net.UDPConn) *net.UDPConn {
	n.conn = conn
	return conn
}

// EnableDebugPadding enables debug output for padding operations
func (n *Noize) EnableDebugPadding() {
	n.mu.Lock()
	defer n.mu.Unlock()
	n.debugPadding = true
}

// DisableDebugPadding disables debug output for padding operations
func (n *Noize) DisableDebugPadding() {
	n.mu.Lock()
	defer n.mu.Unlock()
	n.debugPadding = false
}

// ObfuscateWrite obfuscates outgoing QUIC packets
func (n *Noize) ObfuscateWrite(packet []byte, addr *net.UDPAddr) ([]byte, error) {
	if len(packet) == 0 {
		return packet, nil
	}

	// Detect QUIC packet type
	packetType := detectQUICPacketType(packet)

	addrKey := addr.String()

	// Handle Initial packets specially
	if packetType == QUICInitial {
		n.mu.Lock()
		state := n.hsState[addrKey]
		if state == nil {
			state = &handshakeState{}
			n.hsState[addrKey] = state
		}

		if !state.initialSeen {
			state.initialSeen = true
			n.mu.Unlock()

			// Execute pre-handshake obfuscation sequence
			go n.executePreHandshake(addr)

			// Apply delay before actual handshake
			if n.config.HandshakeDelay > 0 {
				time.Sleep(n.config.HandshakeDelay)
			}
		} else {
			n.mu.Unlock()
		}

		if n.config.FragmentInitial && n.config.FragmentSize > 0 && len(packet) > n.config.FragmentSize {
			return n.fragmentInitialPacket(packet, addr), nil
		}
	}

	if packetType == QUIC1RTT {
		n.mu.Lock()
		state := n.hsState[addrKey]
		if state != nil && !state.postSent {
			state.postSent = true
			n.mu.Unlock()
			go n.executePostHandshake(addr)
		} else {
			n.mu.Unlock()
		}
	}

	// Apply padding
	packet = n.addPadding(packet)

	// Apply protocol wrapper
	if n.config.MimicProtocol != "" {
		packet = n.wrapProtocol(packet, packetType)
	}

	// Apply random delay
	n.applyDelay()

	return packet, nil
}

// executePreHandshake sends signature and junk packets before handshake
func (n *Noize) executePreHandshake(addr *net.UDPAddr) {
	if n.conn == nil {
		return
	}

	if n.debugPadding {
		fmt.Printf("NOIZE_DEBUG: executePreHandshake started for %s\n", addr.String())
		fmt.Printf("NOIZE_DEBUG: JcBeforeHS=%d, JcAfterI1=%d, JcDuringHS=%d\n",
			n.config.JcBeforeHS, n.config.JcAfterI1, n.config.JcDuringHS)
	}

	if n.config.JcBeforeHS > 0 {
		if n.debugPadding {
			fmt.Printf("NOIZE_DEBUG: Sending %d junk packets before handshake\n", n.config.JcBeforeHS)
		}
		for i := 0; i < n.config.JcBeforeHS; i++ {
			junk := n.generateJunkPacket()
			if len(junk) > 0 {
				n.conn.WriteToUDP(junk, addr)
				if n.debugPadding {
					fmt.Printf("NOIZE_DEBUG: Sent %d byte junk packet before HS\n", len(junk))
				}
			}
			n.applyJunkDelay()
		}
	}

	// Send I1 signature packet
	if n.config.I1 != "" {
		i1Packet, err := parseCPSPacket(n.config.I1)
		if err == nil && len(i1Packet) > 0 {
			n.conn.WriteToUDP(i1Packet, addr)
			if n.debugPadding {
				fmt.Printf("NOIZE_DEBUG: Sent I1 signature packet (%d bytes)\n", len(i1Packet))
			}
			time.Sleep(2 * time.Millisecond)
		}
	}

	if n.config.JcAfterI1 > 0 {
		if n.debugPadding {
			fmt.Printf("NOIZE_DEBUG: Sending %d junk packets after I1\n", n.config.JcAfterI1)
		}
		for i := 0; i < n.config.JcAfterI1; i++ {
			junk := n.generateJunkPacket()
			if len(junk) > 0 {
				n.conn.WriteToUDP(junk, addr)
				if n.debugPadding {
					fmt.Printf("NOIZE_DEBUG: Sent %d byte junk packet after I1\n", len(junk))
				}
			}
			n.applyJunkDelay()
		}
	}

	// Send I2-I5 signature packets
	signatures := []string{n.config.I2, n.config.I3, n.config.I4, n.config.I5}
	for _, sig := range signatures {
		if sig == "" {
			continue
		}
		packet, err := parseCPSPacket(sig)
		if err == nil && len(packet) > 0 {
			n.conn.WriteToUDP(packet, addr)
			if n.debugPadding {
				fmt.Printf("NOIZE_DEBUG: Sent signature packet (%d bytes)\n", len(packet))
			}
			time.Sleep(1 * time.Millisecond)
		}
	}

	if n.config.JcDuringHS > 0 {
		if n.debugPadding {
			fmt.Printf("NOIZE_DEBUG: Sending %d junk packets during handshake\n", n.config.JcDuringHS)
		}
		for i := 0; i < n.config.JcDuringHS; i++ {
			junk := n.generateJunkPacket()
			if len(junk) > 0 {
				n.conn.WriteToUDP(junk, addr)
				if n.debugPadding {
					fmt.Printf("NOIZE_DEBUG: Sent %d byte junk packet during HS\n", len(junk))
				}
			}
			n.applyJunkDelay()
		}
	}

	if n.debugPadding {
		fmt.Printf("NOIZE_DEBUG: executePreHandshake completed for %s\n", addr.String())
	}
}

func (n *Noize) executePostHandshake(addr *net.UDPAddr) {
	if n.conn == nil {
		return
	}

	if n.config.JcAfterHS > 0 {
		for i := 0; i < n.config.JcAfterHS; i++ {
			junk := n.generateJunkPacket()
			n.conn.WriteToUDP(junk, addr)
			n.applyJunkDelay()
		}
	}
}

func (n *Noize) fragmentInitialPacket(packet []byte, addr *net.UDPAddr) []byte {
	if n.config.FragmentSize <= 0 || len(packet) <= n.config.FragmentSize {
		return packet
	}

	fragmentSize := n.config.FragmentSize

	if n.conn != nil {
		go func() {
			for offset := fragmentSize; offset < len(packet); offset += fragmentSize {
				end := offset + fragmentSize
				if end > len(packet) {
					end = len(packet)
				}

				fragment := packet[offset:end]
				n.conn.WriteToUDP(fragment, addr)

				if n.config.FragmentDelay > 0 {
					time.Sleep(n.config.FragmentDelay)
				}
			}
		}()
	}

	// Return first fragment
	return packet[:fragmentSize]
}

// fragmentPacket splits a packet into smaller fragments
func (n *Noize) fragmentPacket(packet []byte, addr *net.UDPAddr) []byte {
	if n.config.FragmentSize <= 0 || len(packet) <= n.config.FragmentSize {
		return packet
	}

	// For QUIC, we need to be careful about fragmentation
	// We'll return the first fragment and schedule others
	fragmentSize := n.config.FragmentSize

	if n.conn != nil {
		go func() {
			for offset := fragmentSize; offset < len(packet); offset += fragmentSize {
				end := offset + fragmentSize
				if end > len(packet) {
					end = len(packet)
				}

				fragment := packet[offset:end]
				n.conn.WriteToUDP(fragment, addr)

				if n.config.FragmentDelay > 0 {
					time.Sleep(n.config.FragmentDelay)
				}
			}
		}()
	}

	// Return first fragment
	return packet[:fragmentSize]
}

// addPadding adds random padding to packet without breaking QUIC structure
func (n *Noize) addPadding(packet []byte) []byte {
	if n.config.PaddingMax == 0 {
		return packet
	}

	// For QUIC packets, we need to be careful with padding
	// Don't pad if packet is too small or looks like a QUIC control packet
	if len(packet) < 16 {
		return packet
	}

	var paddingSize int
	if n.config.RandomPadding {
		paddingSize = n.config.PaddingMin + rng.Intn(n.config.PaddingMax-n.config.PaddingMin+1)
	} else {
		paddingSize = n.config.PaddingMax
	}

	if paddingSize <= 0 {
		return packet
	}

	// Limit padding size to avoid MTU issues
	originalLen := len(packet)
	if originalLen+paddingSize > 1200 {
		paddingSize = 1200 - originalLen
		if paddingSize <= 0 {
			return packet
		}
	}

	padding := make([]byte, paddingSize)
	rand.Read(padding)

	// Debug: Print padding info (enable via EnableDebugPadding())
	if n.debugPadding {
		fmt.Printf("NOIZE_DEBUG: Added %d bytes padding to %d byte packet (total: %d)\n",
			paddingSize, originalLen, originalLen+paddingSize)
	}

	return append(packet, padding...)
}

// generateJunkPacket creates a junk packet
func (n *Noize) generateJunkPacket() []byte {
	minSize := n.config.Jmin
	maxSize := n.config.Jmax

	// Debug output
	if n.debugPadding {
		fmt.Printf("NOIZE_DEBUG: Generating junk packet - min:%d, max:%d, allowZero:%t\n",
			minSize, maxSize, n.config.AllowZeroSize)
	}

	if minSize == 0 && maxSize == 0 {
		if n.config.AllowZeroSize {
			if n.debugPadding {
				fmt.Printf("NOIZE_DEBUG: Returning zero-size junk packet\n")
			}
			return []byte{}
		}
		if n.debugPadding {
			fmt.Printf("NOIZE_DEBUG: Returning 1-byte fallback junk packet\n")
		}
		return []byte{0x00}
	}

	if !n.config.AllowZeroSize && minSize < 1 {
		minSize = 1
	}

	var size int
	if maxSize == minSize {
		size = minSize
	} else if maxSize > minSize {
		size = minSize + rng.Intn(maxSize-minSize+1)
	} else {
		size = minSize
	}

	if size == 0 && n.config.AllowZeroSize {
		if n.debugPadding {
			fmt.Printf("NOIZE_DEBUG: Returning zero-size junk packet (calculated)\n")
		}
		return []byte{}
	}

	junk := make([]byte, size)
	rand.Read(junk)

	if n.debugPadding {
		fmt.Printf("NOIZE_DEBUG: Generated %d byte junk packet\n", size)
	}

	// Optionally make it look like a protocol packet
	if n.config.MimicProtocol != "" && size > 10 {
		n.applyProtocolMimic(junk)
	}

	return junk
}

// applyDelay applies configured delay
func (n *Noize) applyDelay() {
	if n.config.RandomDelay {
		if n.config.DelayMax > n.config.DelayMin {
			delay := n.config.DelayMin + time.Duration(rng.Int63n(int64(n.config.DelayMax-n.config.DelayMin)))
			time.Sleep(delay)
		}
	} else if n.config.PacketDelay > 0 {
		time.Sleep(n.config.PacketDelay)
	}
}

// applyJunkDelay applies junk packet delay
func (n *Noize) applyJunkDelay() {
	if n.config.JunkRandom {
		if n.config.JunkInterval > 0 {
			maxDelay := n.config.JunkInterval * 2
			delay := time.Duration(rng.Int63n(int64(maxDelay)))
			time.Sleep(delay)
		}
	} else if n.config.JunkInterval > 0 {
		time.Sleep(n.config.JunkInterval)
	}
}

// QUICPacketType represents QUIC packet types
type QUICPacketType int

const (
	QUICInitial QUICPacketType = iota
	QUICHandshake
	QUIC0RTT
	QUIC1RTT
	QUICRetry
	QUICVersionNegotiation
	QUICUnknown
)

// detectQUICPacketType detects the type of QUIC packet
func detectQUICPacketType(packet []byte) QUICPacketType {
	if len(packet) < 1 {
		return QUICUnknown
	}

	headerByte := packet[0]

	// Long header (bit 7 set)
	if headerByte&0x80 != 0 {
		if len(packet) < 5 {
			return QUICUnknown
		}

		// Extract packet type from bits 4-5
		packetType := (headerByte >> 4) & 0x03

		switch packetType {
		case 0x00:
			return QUICInitial
		case 0x01:
			return QUIC0RTT
		case 0x02:
			return QUICHandshake
		case 0x03:
			return QUICRetry
		}
	}

	// Short header (1-RTT packet)
	return QUIC1RTT
}

// parseCPSPacket parses Custom Protocol Signature format
func parseCPSPacket(cps string) ([]byte, error) {
	if cps == "" {
		return nil, nil
	}

	var result []byte

	tagRegex := regexp.MustCompile(`<([btcrnx])\s*([^>]*)>`)
	matches := tagRegex.FindAllStringSubmatch(cps, -1)

	for _, match := range matches {
		if len(match) < 3 {
			continue
		}

		tagType := match[1]
		tagData := strings.TrimSpace(match[2])

		switch tagType {
		case "b": // Static bytes (hex)
			if tagData != "" {
				tagData = strings.TrimPrefix(tagData, "0x")
				tagData = strings.TrimPrefix(tagData, "0X")
				tagData = strings.ReplaceAll(tagData, " ", "")
				bytes, err := hex.DecodeString(tagData)
				if err != nil {
					return nil, fmt.Errorf("invalid hex in <b>: %w", err)
				}
				result = append(result, bytes...)
			}

		case "c": // Counter (32-bit)
			counter := uint32(time.Now().Unix() % 0xFFFFFFFF)
			buf := make([]byte, 4)
			binary.BigEndian.PutUint32(buf, counter)
			result = append(result, buf...)

		case "t": // Timestamp (32-bit)
			timestamp := uint32(time.Now().Unix())
			buf := make([]byte, 4)
			binary.BigEndian.PutUint32(buf, timestamp)
			result = append(result, buf...)

		case "r": // Random bytes
			length := 0
			if tagData != "" {
				length, _ = strconv.Atoi(tagData)
				if length > 1000 {
					length = 1000
				}
			}
			if length > 0 {
				randomBytes := make([]byte, length)
				rand.Read(randomBytes)
				result = append(result, randomBytes...)
			}

		case "n": // Nonce (64-bit)
			nonce := uint64(time.Now().UnixNano())
			buf := make([]byte, 8)
			binary.BigEndian.PutUint64(buf, nonce)
			result = append(result, buf...)

		case "x": // XOR key (for simple obfuscation)
			if tagData != "" {
				key, _ := strconv.Atoi(tagData)
				if len(result) > 0 {
					for i := range result {
						result[i] ^= byte(key)
					}
				}
			}
		}
	}

	return result, nil
}

// wrapProtocol wraps packet in protocol-specific format
func (n *Noize) wrapProtocol(packet []byte, packetType QUICPacketType) []byte {
	switch n.config.MimicProtocol {
	case "dns":
		return n.wrapDNS(packet)
	case "https", "h3":
		return n.wrapHTTPS(packet)
	case "dtls":
		return n.wrapDTLS(packet)
	case "stun":
		return n.wrapSTUN(packet)
	default:
		return packet
	}
}

// wrapDNS wraps packet as DNS query
func (n *Noize) wrapDNS(packet []byte) []byte {
	// DNS header (12 bytes)
	header := make([]byte, 12)
	binary.BigEndian.PutUint16(header[0:2], uint16(rng.Intn(65536))) // Transaction ID
	binary.BigEndian.PutUint16(header[2:4], 0x0100)                  // Flags: Standard query
	binary.BigEndian.PutUint16(header[4:6], 1)                       // Questions: 1

	// Append original packet as "answer" data
	return append(header, packet...)
}

// wrapHTTPS wraps packet as HTTPS/HTTP3 data
func (n *Noize) wrapHTTPS(packet []byte) []byte {
	// Add TLS record header (5 bytes)
	header := make([]byte, 5)
	header[0] = 0x17 // Application Data
	header[1] = 0x03 // TLS 1.2
	header[2] = 0x03
	binary.BigEndian.PutUint16(header[3:5], uint16(len(packet)))

	return append(header, packet...)
}

// wrapDTLS wraps packet as DTLS
func (n *Noize) wrapDTLS(packet []byte) []byte {
	// DTLS record header (13 bytes)
	header := make([]byte, 13)
	header[0] = 0x17 // Application Data
	header[1] = 0xfe // DTLS 1.2
	header[2] = 0xfd
	binary.BigEndian.PutUint16(header[3:5], uint16(rng.Intn(65536))) // Epoch
	// Sequence number (6 bytes) at 5-11
	binary.BigEndian.PutUint16(header[11:13], uint16(len(packet)))

	return append(header, packet...)
}

// wrapSTUN wraps packet as STUN message
func (n *Noize) wrapSTUN(packet []byte) []byte {
	// STUN header (20 bytes)
	header := make([]byte, 20)
	binary.BigEndian.PutUint16(header[0:2], 0x0001)              // Binding Request
	binary.BigEndian.PutUint16(header[2:4], uint16(len(packet))) // Length
	binary.BigEndian.PutUint32(header[4:8], 0x2112A442)          // Magic Cookie
	rand.Read(header[8:20])                                      // Transaction ID

	return append(header, packet...)
}

// applyProtocolMimic makes junk packet look like a protocol packet
func (n *Noize) applyProtocolMimic(junk []byte) {
	switch n.config.MimicProtocol {
	case "dns":
		// Make it look like DNS
		if len(junk) >= 12 {
			binary.BigEndian.PutUint16(junk[0:2], uint16(rng.Intn(65536)))
			binary.BigEndian.PutUint16(junk[2:4], 0x0100)
		}
	case "https", "h3":
		// Make it look like TLS
		if len(junk) >= 5 {
			junk[0] = 0x17
			junk[1] = 0x03
			junk[2] = 0x03
		}
	case "stun":
		// Make it look like STUN
		if len(junk) >= 20 {
			binary.BigEndian.PutUint16(junk[0:2], 0x0001)
			binary.BigEndian.PutUint32(junk[4:8], 0x2112A442)
		}
	}
}

// LoadConfigFromFile loads NoizeConfig from a JSON file
func LoadConfigFromFile(filepath string) (*NoizeConfig, error) {
	data, err := os.ReadFile(filepath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	// First unmarshal into a generic map to handle duration strings
	var rawConfig map[string]interface{}
	if err := json.Unmarshal(data, &rawConfig); err != nil {
		return nil, fmt.Errorf("failed to parse config JSON: %w", err)
	}

	config := &NoizeConfig{}

	// Handle all duration fields manually
	durationFields := []string{"JunkInterval", "HandshakeDelay", "PacketDelay", "DelayMin", "DelayMax", "FragmentDelay"}

	for _, field := range durationFields {
		if val, ok := rawConfig[field]; ok {
			if strVal, ok := val.(string); ok {
				if dur, err := time.ParseDuration(strVal); err == nil {
					switch field {
					case "JunkInterval":
						config.JunkInterval = dur
					case "HandshakeDelay":
						config.HandshakeDelay = dur
					case "PacketDelay":
						config.PacketDelay = dur
					case "DelayMin":
						config.DelayMin = dur
					case "DelayMax":
						config.DelayMax = dur
					case "FragmentDelay":
						config.FragmentDelay = dur
					}
				}
			}
			delete(rawConfig, field)
		}
	}

	// Convert back to JSON and unmarshal into struct for other fields
	remainingData, err := json.Marshal(rawConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal remaining config: %w", err)
	}

	if err := json.Unmarshal(remainingData, config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	return config, nil
}

// SaveConfigToFile saves NoizeConfig to a JSON file
func (c *NoizeConfig) SaveConfigToFile(filepath string) error {
	// Create a map for manual JSON creation to avoid recursion issues
	configMap := map[string]interface{}{
		"I1":               c.I1,
		"I2":               c.I2,
		"I3":               c.I3,
		"I4":               c.I4,
		"I5":               c.I5,
		"FragmentSize":     c.FragmentSize,
		"FragmentInitial":  c.FragmentInitial,
		"PaddingMin":       c.PaddingMin,
		"PaddingMax":       c.PaddingMax,
		"RandomPadding":    c.RandomPadding,
		"Jc":               c.Jc,
		"Jmin":             c.Jmin,
		"Jmax":             c.Jmax,
		"JcBeforeHS":       c.JcBeforeHS,
		"JcAfterI1":        c.JcAfterI1,
		"JcDuringHS":       c.JcDuringHS,
		"JcAfterHS":        c.JcAfterHS,
		"JunkRandom":       c.JunkRandom,
		"MimicProtocol":    c.MimicProtocol,
		"CustomWrapper":    c.CustomWrapper,
		"RandomDelay":      c.RandomDelay,
		"ReversedOrder":    c.ReversedOrder,
		"DuplicatePackets": c.DuplicatePackets,
		"AllowZeroSize":    c.AllowZeroSize,
		"UseTimestamp":     c.UseTimestamp,
		"UseNonce":         c.UseNonce,
		"RandomizeInitial": c.RandomizeInitial,
		"FakeLoss":         c.FakeLoss,
		"SNIFragmentation": c.SNIFragmentation,
		"SNIFragment":      c.SNIFragment,
	}

	// Add duration fields as strings (include zero values too)
	configMap["JunkInterval"] = c.JunkInterval.String()
	configMap["HandshakeDelay"] = c.HandshakeDelay.String()
	configMap["PacketDelay"] = c.PacketDelay.String()
	configMap["DelayMin"] = c.DelayMin.String()
	configMap["DelayMax"] = c.DelayMax.String()
	configMap["FragmentDelay"] = c.FragmentDelay.String()

	// Add slice fields
	if len(c.FakeALPN) > 0 {
		configMap["FakeALPN"] = c.FakeALPN
	}

	data, err := json.MarshalIndent(configMap, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	if err := os.WriteFile(filepath, data, 0644); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

// ExportPresetToFile saves a preset configuration to a JSON file for customization
func ExportPresetToFile(presetName, filepath string) error {
	var config *NoizeConfig

	switch presetName {
	case "minimal":
		config = MinimalObfuscationConfig()
	case "light":
		config = LightObfuscationConfig()
	case "medium":
		config = MediumObfuscationConfig()
	case "heavy":
		config = HeavyObfuscationConfig()
	case "stealth":
		config = StealthObfuscationConfig()
	case "gfw":
		config = GFWBypassConfig()
	case "firewall":
		config = FirewallBypassConfig()
	default:
		return fmt.Errorf("unknown preset: %s", presetName)
	}

	return config.SaveConfigToFile(filepath)
}
