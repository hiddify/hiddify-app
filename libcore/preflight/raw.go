package preflight

import (
	"context"
	"encoding/hex"
	"errors"
	"net"
	"strings"
	"time"
)

// normalize returns a payload sized exactly target bytes:
// - if buf is longer, it truncates (keeps the first target bytes).
// - if buf is shorter, it pads with zeros to target bytes.
func normalize(buf []byte, target int) []byte {
	switch {
	case len(buf) == target:
		return buf
	case len(buf) > target:
		return buf[:target]
	default:
		out := make([]byte, target)
		copy(out, buf)
		return out
	}
}

// SendRawHexOnce sends a single UDP datagram containing the provided hex blob
// to dstIP:dstPort. If minBytes > 0, the payload is normalized to exactly minBytes.
// Use minBytes = 1200 to mimic a QUIC Initial payload size (RFC 9000 §14.1).
func SendRawHexOnce(ctx context.Context, dstIP string, dstPort int, hexBlob string, minBytes int) error {
	h := strings.TrimSpace(hexBlob)
	h = strings.TrimPrefix(h, "0x")
	if h == "" {
		return errors.New("empty hex blob")
	}
	b, err := hex.DecodeString(h)
	if err != nil {
		return err
	}
	if minBytes > 0 {
		b = normalize(b, minBytes)
	}

	raddr, err := net.ResolveUDPAddr("udp", net.JoinHostPort(dstIP, intToStr(dstPort)))
	if err != nil {
		return err
	}
	conn, err := net.DialUDP("udp", nil, raddr)
	if err != nil {
		return err
	}
	defer conn.Close()

	_ = conn.SetWriteDeadline(time.Now().Add(2 * time.Second))
	_, err = conn.Write(b)
	return err
}

func intToStr(n int) string {
	// small, dependency-free itoa
	if n == 0 {
		return "0"
	}
	sign := ""
	if n < 0 {
		sign = "-"
		n = -n
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	return sign + string(buf[i:])
}
