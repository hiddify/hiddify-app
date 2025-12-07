package socks4

import (
	"bytes"
	"encoding/binary"
	"io"
	"net"
	"strconv"
)

var (
	isSocks4a = []byte{0, 0, 0, 1}
	isNone    = []byte{0, 0, 0, 0}
)

const (
	socks4Version = 0x04
)

const (
	ConnectCommand Command = 0x01
)

// Command is a SOCKS Command.
type Command byte

func (cmd Command) String() string {
	switch cmd {
	case ConnectCommand:
		return "socks connect"
	default:
		return "socks " + strconv.Itoa(int(cmd))
	}
}

const (
	grantedReply     reply = 0x5a
	rejectedReply    reply = 0x5b
	noIdentdReply    reply = 0x5c
	invalidUserReply reply = 0x5d
)

// reply is a SOCKS Command reply code.
type reply byte

func (code reply) String() string {
	switch code {
	case grantedReply:
		return "request granted"
	case rejectedReply:
		return "request rejected or failed"
	case noIdentdReply:
		return "request rejected becasue SOCKS server cannot connect to identd on the client"
	case invalidUserReply:
		return "request rejected because the client program and identd report different user-ids"
	default:
		return "unknown code: " + strconv.Itoa(int(code))
	}
}

// address is a SOCKS-specific address.
// Either Name or IP is used exclusively.
type address struct {
	Name string // fully-qualified domain name
	IP   net.IP
	Port int
}

func (a *address) Network() string { return "socks4" }

func (a *address) String() string {
	if a == nil {
		return "<nil>"
	}
	return a.Address()
}

// Address returns a string suitable to dial; prefer returning IP-based
// address, fallback to Name
func (a address) Address() string {
	port := strconv.Itoa(a.Port)
	if a.Name != "" {
		return net.JoinHostPort(a.Name, port)
	}
	return net.JoinHostPort(a.IP.String(), port)
}

type AddrAnfUser struct {
	address
	Username string
}

func readBytes(r io.Reader) ([]byte, error) {
	buf := []byte{}
	var data [1]byte
	for {
		_, err := r.Read(data[:])
		if err != nil {
			return nil, err
		}
		if data[0] == 0 {
			return buf, nil
		}
		buf = append(buf, data[0])
	}
}

func readByte(r io.Reader) (byte, error) {
	var buf [1]byte
	_, err := r.Read(buf[:])
	if err != nil {
		return 0, err
	}
	return buf[0], nil
}

func readAddrAndUser(r io.Reader) (*AddrAnfUser, error) {
	address := &AddrAnfUser{}
	var port [2]byte
	if _, err := io.ReadFull(r, port[:]); err != nil {
		return nil, err
	}
	address.Port = int(binary.BigEndian.Uint16(port[:]))
	ip := make(net.IP, net.IPv4len)
	if _, err := io.ReadFull(r, ip); err != nil {
		return nil, err
	}
	socks4a := bytes.Equal(ip, isSocks4a)

	username, err := readBytes(r)
	if err != nil {
		return nil, err
	}
	address.Username = string(username)
	if socks4a {
		hostname, err := readBytes(r)
		if err != nil {
			return nil, err
		}
		address.Name = string(hostname)
	} else {
		address.IP = ip
	}
	return address, nil
}

func writeAddr(w io.Writer, addr *address) error {
	var ip net.IP
	var port uint16
	if addr != nil {
		ip = addr.IP.To4()
		port = uint16(addr.Port)
	}
	var p [2]byte
	binary.BigEndian.PutUint16(p[:], port)
	_, err := w.Write(p[:])
	if err != nil {
		return err
	}

	if ip == nil {
		_, err = w.Write(isNone)
	} else {
		_, err = w.Write(ip)
	}
	return err
}
