package ping

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/netip"
	"os"
	"time"

	"github.com/bepass-org/vwarp/ipscanner/statute"
)

// Minimal ICMP echo implementation.

// IcmpPingResult stores the result of an ICMP ping.
type IcmpPingResult struct {
	Addr netip.Addr
	RTT  time.Duration
	Err  error
}

func (r *IcmpPingResult) Result() statute.IPInfo {
	// ICMP doesn't have a port, so we return 0.
	return statute.IPInfo{AddrPort: netip.AddrPortFrom(r.Addr, 0), RTT: r.RTT, CreatedAt: time.Now()}
}

func (r *IcmpPingResult) Error() error {
	return r.Err
}

func (r *IcmpPingResult) String() string {
	if r.Err != nil {
		return fmt.Sprintf("%s", r.Err)
	}
	return fmt.Sprintf("%s: time=%d ms", r.Addr, r.RTT.Milliseconds())
}

// IcmpPing represents an ICMP ping operation.
type IcmpPing struct {
	ip   netip.Addr
	opts *statute.ScannerOptions
}

// NewIcmpPing creates a new IcmpPing instance.
func NewIcmpPing(ip netip.Addr, opts *statute.ScannerOptions) *IcmpPing {
	return &IcmpPing{ip: ip, opts: opts}
}

func (p *IcmpPing) Ping() statute.IPingResult {
	return p.PingContext(context.Background())
}

func (p *IcmpPing) PingContext(ctx context.Context) statute.IPingResult {
	if !p.ip.IsValid() {
		return &IcmpPingResult{Err: errors.New("no IP specified")}
	}

	var network, address string
	if p.ip.Is4() {
		network = "ip4:icmp"
		address = p.ip.String()
	} else if p.ip.Is6() {
		network = "ip6:ipv6-icmp"
		address = p.ip.String()
	} else {
		return &IcmpPingResult{Err: errors.New("unsupported IP address family")}
	}

	// The dialer's timeout will act as the overall timeout for the operation.
	dialer := net.Dialer{Timeout: p.opts.ConnectionTimeout}

	// We use DialContext to respect context cancellation.
	conn, err := dialer.DialContext(ctx, network, address)
	if err != nil {
		return &IcmpPingResult{Addr: p.ip, Err: err}
	}
	defer conn.Close()

	// Construct ICMP Echo message
	var msgType byte
	if p.ip.Is4() {
		msgType = 8 // Echo Request
	} else {
		msgType = 128 // Echo Request
	}

	// Message format: Type (8), Code (8), Checksum (16), ID (16), Seq (16), Data
	// Using process ID for a somewhat unique identifier.
	id := os.Getpid() & 0xffff
	seq := 1 // Sequence number

	// Simple message construction
	msg := make([]byte, 8)
	msg[0] = msgType // Type
	msg[1] = 0       // Code
	msg[2] = 0       // Checksum (placeholder)
	msg[3] = 0       // Checksum (placeholder)
	msg[4] = byte(id >> 8)
	msg[5] = byte(id & 0xff)
	msg[6] = byte(seq >> 8)
	msg[7] = byte(seq & 0xff)

	cs := checksum(msg)
	msg[2] = byte(cs >> 8)
	msg[3] = byte(cs & 0xff)

	t0 := time.Now()
	if _, err := conn.Write(msg); err != nil {
		return &IcmpPingResult{Addr: p.ip, Err: err}
	}

	reply := make([]byte, 1500)
	if err := conn.SetReadDeadline(time.Now().Add(p.opts.ConnectionTimeout)); err != nil {
		return &IcmpPingResult{Addr: p.ip, Err: err}
	}

	n, err := conn.Read(reply)
	if err != nil {
		return &IcmpPingResult{Addr: p.ip, Err: err}
	}
	rtt := time.Since(t0)

	// Minimal validation: check if it's an echo reply
	var replyType byte
	if p.ip.Is4() {
		// For IPv4, the reply starts after the 20-byte IP header
		if n < 20+8 {
			return &IcmpPingResult{Addr: p.ip, Err: errors.New("invalid ICMP reply: too short")}
		}
		replyType = reply[20]
		if replyType != 0 { // Echo Reply
			return &IcmpPingResult{Addr: p.ip, Err: fmt.Errorf("not an echo reply, type: %d", replyType)}
		}
	} else { // IPv6
		replyType = reply[0]
		if replyType != 129 { // Echo Reply
			return &IcmpPingResult{Addr: p.ip, Err: fmt.Errorf("not an echo reply, type: %d", replyType)}
		}
	}

	return &IcmpPingResult{Addr: p.ip, RTT: rtt, Err: nil}
}

func checksum(data []byte) uint16 {
	var sum uint32
	for i := 0; i+1 < len(data); i += 2 {
		sum += uint32(data[i])<<8 | uint32(data[i+1])
	}
	if len(data)%2 == 1 {
		sum += uint32(data[len(data)-1]) << 8
	}
	for sum>>16 > 0 {
		sum = (sum & 0xffff) + (sum >> 16)
	}
	return uint16(^sum)
}

var (
	_ statute.IPing       = (*IcmpPing)(nil)
	_ statute.IPingResult = (*IcmpPingResult)(nil)
)
