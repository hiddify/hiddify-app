package statute

import (
	"context"
	"fmt"
	"io"
	"net"
)

type Logger interface {
	Debug(v ...interface{})
	Error(v ...interface{})
}

type DefaultLogger struct{}

func (l DefaultLogger) Debug(v ...interface{}) {
	fmt.Println(v...)
}

func (l DefaultLogger) Error(v ...interface{}) {
	fmt.Println(v...)
}

type ProxyRequest struct {
	Conn        net.Conn
	Reader      io.Reader
	Writer      io.Writer
	Network     string
	Destination string
	DestHost    string
	DestPort    int32
}

// UserConnectHandler is used for socks5, socks4 and http
type UserConnectHandler func(request *ProxyRequest) error

// UserAssociateHandler is used for socks5
type UserAssociateHandler func(request *ProxyRequest) error

// ProxyDialFunc is used for socks5, socks4 and http
type ProxyDialFunc func(ctx context.Context, network string, address string) (net.Conn, error)

// DefaultProxyDial for ProxyDialFunc type
func DefaultProxyDial() ProxyDialFunc {
	var dialer net.Dialer
	return dialer.DialContext
}

// ProxyListenPacket specifies the optional proxyListenPacket function for
// establishing the transport connection.
type ProxyListenPacket func(ctx context.Context, network string, address string) (net.PacketConn, error)

// DefaultProxyListenPacket for ProxyListenPacket type
func DefaultProxyListenPacket() ProxyListenPacket {
	var listener net.ListenConfig
	return listener.ListenPacket
}

// PacketForwardAddress specifies the packet forwarding address
type PacketForwardAddress func(ctx context.Context, destinationAddr string,
	packet net.PacketConn, conn net.Conn) (net.IP, int, error)

// BytesPool is an interface for getting and returning temporary
// bytes for use by io.CopyBuffer.
type BytesPool interface {
	Get() []byte
	Put([]byte)
}

// DefaultContext for context.Context type
func DefaultContext() context.Context {
	return context.Background()
}

const DefaultBindAddress = "127.0.0.1:1080"
