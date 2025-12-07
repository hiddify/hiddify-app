package socks4

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net"

	"github.com/bepass-org/vwarp/proxy/pkg/statute"
)

// Server is accepting connections and handling the details of the SOCKS4 protocol
type Server struct {
	// bind is the address to listen on
	Bind string

	Listener net.Listener

	// ProxyDial specifies the optional proxyDial function for
	// establishing the transport connection.
	ProxyDial statute.ProxyDialFunc
	// UserConnectHandle gives the user control to handle the TCP CONNECT requests
	UserConnectHandle statute.UserConnectHandler
	// Logger error log
	Logger *slog.Logger
	// Context is default context
	Context context.Context
	// BytesPool getting and returning temporary bytes for use by io.CopyBuffer
	BytesPool statute.BytesPool
}

func NewServer(options ...ServerOption) *Server {
	s := &Server{
		ProxyDial: statute.DefaultProxyDial(),
		Logger:    slog.Default(),
		Context:   statute.DefaultContext(),
	}

	for _, option := range options {
		option(s)
	}

	return s
}

type ServerOption func(*Server)

func (s *Server) ListenAndServe() error {
	// Create a new listener
	if s.Listener == nil {
		ln, err := net.Listen("tcp", s.Bind)
		if err != nil {
			return err // Return error if binding was unsuccessful
		}
		s.Listener = ln
	}

	s.Bind = s.Listener.Addr().(*net.TCPAddr).String()

	// ensure listener will be closed
	defer func() {
		_ = s.Listener.Close()
	}()

	// Create a cancelable context based on s.Context
	ctx, cancel := context.WithCancel(s.Context)
	defer cancel() // Ensure resources are cleaned up

	// Start to accept connections and serve them
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			conn, err := s.Listener.Accept()
			if err != nil {
				s.Logger.Error(err.Error())
				continue
			}

			// Start a new goroutine to handle each connection
			// This way, the server can handle multiple connections concurrently
			go func() {
				err := s.ServeConn(conn)
				if err != nil {
					s.Logger.Error(err.Error()) // Log errors from ServeConn
				}
			}()
		}
	}
}

func WithLogger(logger *slog.Logger) ServerOption {
	return func(s *Server) {
		s.Logger = logger
	}
}

func WithBind(bindAddress string) ServerOption {
	return func(s *Server) {
		s.Bind = bindAddress
	}
}

func WithConnectHandle(handler statute.UserConnectHandler) ServerOption {
	return func(s *Server) {
		s.UserConnectHandle = handler
	}
}

func WithProxyDial(proxyDial statute.ProxyDialFunc) ServerOption {
	return func(s *Server) {
		s.ProxyDial = proxyDial
	}
}

func WithContext(ctx context.Context) ServerOption {
	return func(s *Server) {
		s.Context = ctx
	}
}

func WithBytesPool(bytesPool statute.BytesPool) ServerOption {
	return func(s *Server) {
		s.BytesPool = bytesPool
	}
}

func (s *Server) ServeConn(conn net.Conn) error {
	version, err := readByte(conn)
	if err != nil {
		return err
	}
	if version != socks4Version {
		return fmt.Errorf("unsupported SOCKS version: %d", version)
	}
	req := &request{
		Version: socks4Version,
		Conn:    conn,
	}

	cmd, err := readByte(conn)
	if err != nil {
		return err
	}
	req.Command = Command(cmd)

	addr, err := readAddrAndUser(conn)
	if err != nil {
		if err := sendReply(req.Conn, rejectedReply, nil); err != nil {
			return fmt.Errorf("failed to send reply: %v", err)
		}
		return err
	}
	req.DestinationAddr = &addr.address
	req.Username = addr.Username
	return s.handle(req)
}

func (s *Server) handle(req *request) error {
	switch req.Command {
	case ConnectCommand:
		return s.handleConnect(req)
	default:
		if err := sendReply(req.Conn, rejectedReply, nil); err != nil {
			return err
		}
		return fmt.Errorf("unsupported Command: %v", req.Command)
	}
}

func (s *Server) handleConnect(req *request) error {
	if s.UserConnectHandle == nil {
		return s.embedHandleConnect(req)
	}

	if err := sendReply(req.Conn, grantedReply, nil); err != nil {
		return fmt.Errorf("failed to send reply: %v", err)
	}
	host := req.DestinationAddr.IP.String()
	if req.DestinationAddr.Name != "" {
		host = req.DestinationAddr.Name
	}

	proxyReq := &statute.ProxyRequest{
		Conn:        req.Conn,
		Reader:      io.Reader(req.Conn),
		Writer:      io.Writer(req.Conn),
		Network:     "tcp",
		Destination: req.DestinationAddr.String(),
		DestHost:    host,
		DestPort:    int32(req.DestinationAddr.Port),
	}

	return s.UserConnectHandle(proxyReq)
}

func (s *Server) embedHandleConnect(req *request) error {
	defer func() {
		_ = req.Conn.Close()
	}()
	target, err := s.ProxyDial(s.Context, "tcp", req.DestinationAddr.Address())
	if err != nil {
		if err := sendReply(req.Conn, rejectedReply, nil); err != nil {
			return fmt.Errorf("failed to send reply: %v", err)
		}
		return fmt.Errorf("connect to %v failed: %w", req.DestinationAddr, err)
	}
	defer func() {
		_ = target.Close()
	}()
	local := target.LocalAddr().(*net.TCPAddr)
	bind := address{IP: local.IP, Port: local.Port}
	if err := sendReply(req.Conn, grantedReply, &bind); err != nil {
		return fmt.Errorf("failed to send reply: %v", err)
	}

	var buf1, buf2 []byte
	if s.BytesPool != nil {
		buf1 = s.BytesPool.Get()
		buf2 = s.BytesPool.Get()
		defer func() {
			s.BytesPool.Put(buf1)
			s.BytesPool.Put(buf2)
		}()
	} else {
		buf1 = make([]byte, 32*1024)
		buf2 = make([]byte, 32*1024)
	}
	return statute.Tunnel(s.Context, target, req.Conn, buf1, buf2)
}

func sendReply(w io.Writer, resp reply, addr *address) error {
	_, err := w.Write([]byte{0, byte(resp)})
	if err != nil {
		return err
	}
	err = writeAddr(w, addr)
	return err
}

type request struct {
	Version         uint8
	Command         Command
	DestinationAddr *address
	Username        string
	Conn            net.Conn
}
