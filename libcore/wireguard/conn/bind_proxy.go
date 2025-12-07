package conn

import (
	"encoding/binary"
	"fmt"
	"io"
	"net"
	"net/netip"
	"net/url"
	"strconv"
	"sync"
	"syscall"
	"time"
)

var _ Bind = (*ProxyBind)(nil)

type ProxyBind struct {
	mu           sync.Mutex
	proxyAddr    string
	proxyConn    net.Conn
	udpConn      *net.UDPConn
	udpRelayAddr *net.UDPAddr
}

func NewProxyBind(proxyAddr string) Bind {
	if proxyAddr == "" {
		return NewStdNetBind()
	}
	var host string
	var port int
	if u, err := url.Parse(proxyAddr); err == nil && u.Host != "" {
		host = u.Hostname()
		portStr := u.Port()
		if portStr != "" {
			port, _ = strconv.Atoi(portStr)
		}
	} else {
		h, p, err := net.SplitHostPort(proxyAddr)
		if err == nil {
			host = h
			port, _ = strconv.Atoi(p)
		} else {
			return NewStdNetBind()
		}
	}
	if port == 0 {
		port = 1080
	}
	proxyAddress := net.JoinHostPort(host, strconv.Itoa(port))
	pb := &ProxyBind{proxyAddr: proxyAddress}
	return pb
}
func (s *ProxyBind) establishUDPAssociation() error {
	conn, err := net.DialTimeout("tcp", s.proxyAddr, 10*time.Second)
	if err != nil {
		return err
	}
	s.proxyConn = conn
	if _, err := conn.Write([]byte{0x05, 0x01, 0x00}); err != nil {
		conn.Close()
		return err
	}
	buf := make([]byte, 2)
	if _, err := io.ReadFull(conn, buf); err != nil {
		conn.Close()
		return err
	}
	if buf[0] != 0x05 || buf[1] != 0x00 {
		conn.Close()
		return fmt.Errorf("auth failed")
	}
	udpConn, err := net.ListenUDP("udp", &net.UDPAddr{IP: net.IPv4zero, Port: 0})
	if err != nil {
		conn.Close()
		return err
	}
	s.udpConn = udpConn
	request := []byte{0x05, 0x03, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	if _, err := conn.Write(request); err != nil {
		conn.Close()
		udpConn.Close()
		return err
	}
	response := make([]byte, 10)
	if _, err := io.ReadFull(conn, response); err != nil {
		conn.Close()
		udpConn.Close()
		return err
	}
	if response[0] != 0x05 || response[1] != 0x00 {
		conn.Close()
		udpConn.Close()
		return fmt.Errorf("UDP ASSOCIATE failed")
	}
	relayIP := net.IPv4(response[4], response[5], response[6], response[7])
	relayPort := int(binary.BigEndian.Uint16(response[8:10]))
	if relayIP.IsUnspecified() {
		proxyHost, _, _ := net.SplitHostPort(s.proxyAddr)
		relayIP = net.ParseIP(proxyHost)
	}
	s.udpRelayAddr = &net.UDPAddr{IP: relayIP, Port: relayPort}
	return nil
}
func (s *ProxyBind) Open(port uint16) ([]ReceiveFunc, uint16, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.udpConn == nil {
		fmt.Printf("[PROXY] Establishing UDP association to %s\n", s.proxyAddr)
		if err := s.establishUDPAssociation(); err != nil {
			fmt.Printf("[PROXY] Failed to establish UDP association: %v\n", err)
			return nil, 0, fmt.Errorf("proxy initialization failed: %w", err)
		}
		fmt.Printf("[PROXY] UDP association established, relay: %s\n", s.udpRelayAddr)
	}
	localAddr := s.udpConn.LocalAddr().(*net.UDPAddr)
	fns := []ReceiveFunc{s.receiveIPv4}
	return fns, uint16(localAddr.Port), nil
}
func (s *ProxyBind) receiveIPv4(packets [][]byte, sizes []int, eps []Endpoint) (n int, err error) {
	s.mu.Lock()
	conn := s.udpConn
	s.mu.Unlock()
	if conn == nil {
		return 0, net.ErrClosed
	}
	buf := make([]byte, 65535)
	size, _, err := conn.ReadFromUDP(buf)
	if err != nil {
		return 0, err
	}
	if size < 10 {
		return 0, nil
	}
	atyp := buf[3]
	var destAddr netip.Addr
	var destPort uint16
	var headerLen int
	if atyp == 0x01 {
		if size < 10 {
			return 0, nil
		}
		destIP := net.IPv4(buf[4], buf[5], buf[6], buf[7])
		destPort = binary.BigEndian.Uint16(buf[8:10])
		headerLen = 10
		destAddr, _ = netip.AddrFromSlice(destIP)
	} else if atyp == 0x04 {
		if size < 22 {
			return 0, nil
		}
		destIP := buf[4:20]
		destPort = binary.BigEndian.Uint16(buf[20:22])
		headerLen = 22
		destAddr, _ = netip.AddrFromSlice(destIP)
	} else {
		return 0, nil
	}
	payloadSize := size - headerLen
	if payloadSize > len(packets[0]) {
		payloadSize = len(packets[0])
	}
	copy(packets[0], buf[headerLen:headerLen+payloadSize])
	sizes[0] = payloadSize
	eps[0] = &StdNetEndpoint{AddrPort: netip.AddrPortFrom(destAddr, destPort)}
	return 1, nil
}
func (s *ProxyBind) Send(bufs [][]byte, ep Endpoint) error {
	s.mu.Lock()
	udpConn := s.udpConn
	relayAddr := s.udpRelayAddr
	s.mu.Unlock()
	if udpConn == nil || relayAddr == nil {
		return syscall.EINVAL
	}
	stdEp, ok := ep.(*StdNetEndpoint)
	if !ok {
		return ErrWrongEndpointType
	}
	addr := stdEp.DstIP()
	port := stdEp.Port()
	var header []byte
	if addr.Is4() {
		header = make([]byte, 10)
		header[0] = 0x00
		header[1] = 0x00
		header[2] = 0x00
		header[3] = 0x01
		copy(header[4:8], addr.AsSlice())
		binary.BigEndian.PutUint16(header[8:10], port)
	} else if addr.Is6() {
		header = make([]byte, 22)
		header[0] = 0x00
		header[1] = 0x00
		header[2] = 0x00
		header[3] = 0x04
		copy(header[4:20], addr.AsSlice())
		binary.BigEndian.PutUint16(header[20:22], port)
	} else {
		return fmt.Errorf("invalid IP address")
	}
	for _, buf := range bufs {
		packet := append(header, buf...)
		_, err := udpConn.WriteToUDP(packet, relayAddr)
		if err != nil {
			return err
		}
	}
	return nil
}
func (s *ProxyBind) SetMark(mark uint32) error {
	return nil
}
func (s *ProxyBind) Close() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.proxyConn != nil {
		s.proxyConn.Close()
		s.proxyConn = nil
	}
	if s.udpConn != nil {
		s.udpConn.Close()
		s.udpConn = nil
	}
	return nil
}
func (s *ProxyBind) ParseEndpoint(endpoint string) (Endpoint, error) {
	e, err := netip.ParseAddrPort(endpoint)
	if err != nil {
		return nil, err
	}
	return &StdNetEndpoint{AddrPort: e}, nil
}
func (s *ProxyBind) BatchSize() int {
	return 1
}
