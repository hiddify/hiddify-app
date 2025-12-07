package http

import (
	"bufio"
	"context"
	"io"
	"log/slog"
	"net"
	"net/http"
	"strconv"

	"github.com/bepass-org/vwarp/proxy/pkg/statute"
)

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
		Bind:      statute.DefaultBindAddress,
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
	reader := bufio.NewReader(conn)
	req, err := http.ReadRequest(reader)
	if err != nil {
		return err
	}

	return s.handleHTTP(conn, req, req.Method == http.MethodConnect)
}

func (s *Server) handleHTTP(conn net.Conn, req *http.Request, isConnectMethod bool) error {
	if s.UserConnectHandle == nil {
		return s.embedHandleHTTP(conn, req, isConnectMethod)
	}

	if isConnectMethod {
		_, err := conn.Write([]byte("HTTP/1.1 200 Connection Established\r\n\r\n"))
		if err != nil {
			return err
		}
	} else {
		cConn := &customConn{
			Conn: conn,
			req:  req,
		}
		conn = cConn
	}

	targetAddr := req.URL.Host
	host, portStr, err := net.SplitHostPort(targetAddr)
	if err != nil {
		host = targetAddr
		if req.URL.Scheme == "https" || isConnectMethod {
			portStr = "443"
		} else {
			portStr = "80"
		}
		targetAddr = net.JoinHostPort(host, portStr)
	}

	portInt, err := strconv.Atoi(portStr)
	if err != nil {
		return err // Handle the error if the port string is not a valid integer.
	}
	port := int32(portInt)

	proxyReq := &statute.ProxyRequest{
		Conn:        conn,
		Reader:      io.Reader(conn),
		Writer:      io.Writer(conn),
		Network:     "tcp",
		Destination: targetAddr,
		DestHost:    host,
		DestPort:    port,
	}

	return s.UserConnectHandle(proxyReq)
}

func (s *Server) embedHandleHTTP(conn net.Conn, req *http.Request, isConnectMethod bool) error {
	defer func() {
		_ = conn.Close()
	}()

	host, portStr, err := net.SplitHostPort(req.URL.Host)
	if err != nil {
		host = req.URL.Host
		if req.URL.Scheme == "https" || isConnectMethod {
			portStr = "443"
		} else {
			portStr = "80"
		}
	}
	targetAddr := net.JoinHostPort(host, portStr)

	target, err := s.ProxyDial(s.Context, "tcp", targetAddr)
	if err != nil {
		http.Error(
			NewHTTPResponseWriter(conn),
			err.Error(),
			http.StatusServiceUnavailable,
		)
		return err
	}
	defer func() {
		_ = target.Close()
	}()

	if isConnectMethod {
		_, err = conn.Write([]byte("HTTP/1.1 200 Connection Established\r\n\r\n"))
		if err != nil {
			return err
		}
	} else {
		err = req.Write(target)
		if err != nil {
			return err
		}
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
	return statute.Tunnel(s.Context, target, conn, buf1, buf2)
}
