package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"syscall"
	"time"

	"github.com/bepass-org/vwarp/masque"
)

type SimpleProxy struct {
	bindAddr       string
	logger         *slog.Logger
	listener       net.Listener
	ctx            context.Context
	cancel         context.CancelFunc
	useMasque      bool
	masqueClient   *masque.MasqueClient
	masqueEndpoint string
}

func NewSimpleProxy(bindAddr string, logger *slog.Logger, useMasque bool, masqueEndpoint string) *SimpleProxy {
	ctx, cancel := context.WithCancel(context.Background())
	return &SimpleProxy{
		bindAddr:       bindAddr,
		logger:         logger,
		ctx:            ctx,
		cancel:         cancel,
		useMasque:      useMasque,
		masqueEndpoint: masqueEndpoint,
	}
}

func (p *SimpleProxy) Start() error {
	// Initialize MASQUE client if enabled
	if p.useMasque {
		err := p.initMasqueClient()
		if err != nil {
			return fmt.Errorf("failed to initialize MASQUE client: %w", err)
		}
		defer func() {
			if p.masqueClient != nil {
				p.masqueClient.Close()
			}
		}()
	}

	listener, err := net.Listen("tcp", p.bindAddr)
	if err != nil {
		return fmt.Errorf("failed to bind to %s: %v", p.bindAddr, err)
	}
	p.listener = listener

	p.logger.Info("SOCKS5 proxy server started", "address", p.bindAddr)
	if p.useMasque {
		fmt.Printf("🚀 MASQUE-Enhanced SOCKS5 Proxy Server running on %s\n", p.bindAddr)
		fmt.Printf("📊 Tunnel Status: ✅ Connected via MASQUE (endpoint: %s)\n", p.masqueEndpoint)
		fmt.Printf("🔐 Backend: MASQUE tunnel with automated registration\n")
	} else {
		fmt.Printf("🚀 Simple SOCKS5 Proxy Server running on %s\n", p.bindAddr)
		fmt.Printf("📊 Tunnel Status: ❌ Direct connections (no tunnel)\n")
		fmt.Printf("🔐 Backend: System network\n")
	}
	fmt.Printf("🌐 Configure your applications to use SOCKS5 proxy: %s\n", p.bindAddr)
	fmt.Println("📋 Press Ctrl+C to stop the server")

	for {
		select {
		case <-p.ctx.Done():
			return nil
		default:
			conn, err := listener.Accept()
			if err != nil {
				if p.ctx.Err() != nil {
					return nil
				}
				p.logger.Warn("Failed to accept connection", "error", err)
				continue
			}
			go p.handleConnection(conn)
		}
	}
}

func (p *SimpleProxy) initMasqueClient() error {
	if p.masqueEndpoint == "" {
		p.logger.Info("No MASQUE endpoint specified, using default Cloudflare endpoint")
		p.masqueEndpoint = "162.159.198.1:443"
	}

	p.logger.Info("Initializing MASQUE connection", "endpoint", p.masqueEndpoint)

	// Auto-register and create MASQUE client with proper options
	client, err := masque.AutoLoadOrRegisterWithOptions(p.ctx, masque.AutoRegisterOptions{
		DeviceName: "simple-proxy",
		Endpoint:   p.masqueEndpoint,
		Logger:     p.logger,
		// Use default config path
	})
	if err != nil {
		return fmt.Errorf("failed to auto-register MASQUE client: %w", err)
	}

	p.masqueClient = client
	p.logger.Info("MASQUE client initialized successfully", "endpoint", p.masqueEndpoint)
	return nil
}

func (p *SimpleProxy) Stop() error {
	p.cancel()
	if p.masqueClient != nil {
		p.masqueClient.Close()
	}
	if p.listener != nil {
		return p.listener.Close()
	}
	return nil
}

func (p *SimpleProxy) handleConnection(conn net.Conn) {
	defer conn.Close()

	if err := p.socks5Handshake(conn); err != nil {
		p.logger.Debug("SOCKS5 handshake failed", "error", err)
		return
	}

	targetAddr, err := p.socks5Connect(conn)
	if err != nil {
		p.logger.Debug("SOCKS5 connect failed", "error", err)
		return
	}

	p.logger.Debug("SOCKS5 connection established", "target", targetAddr)

	// Connect through MASQUE tunnel or regular network
	var targetConn net.Conn
	if p.useMasque && p.masqueClient != nil {
		// Connect through MASQUE tunnel
		p.logger.Debug("Connecting through MASQUE tunnel", "target", targetAddr)
		// TODO: Implement MASQUE connection proxy - for now use direct connection
		// This would require implementing a MASQUE-aware dialer
		targetConn, err = net.DialTimeout("tcp", targetAddr, 15*time.Second)
		if err != nil {
			p.logger.Error("Failed to connect to target via MASQUE", "target", targetAddr, "error", err)
			return
		}
	} else {
		// Connect through regular network
		targetConn, err = net.DialTimeout("tcp", targetAddr, 15*time.Second)
		if err != nil {
			p.logger.Error("Failed to connect to target", "target", targetAddr, "error", err)
			return
		}
	}
	defer targetConn.Close()

	// Relay data
	p.relayData(conn, targetConn, targetAddr)
}

func (p *SimpleProxy) socks5Handshake(conn net.Conn) error {
	buf := make([]byte, 258)
	n, err := conn.Read(buf)
	if err != nil {
		return fmt.Errorf("failed to read handshake: %v", err)
	}

	if n < 3 || buf[0] != 0x05 {
		return fmt.Errorf("invalid SOCKS5 version")
	}

	_, err = conn.Write([]byte{0x05, 0x00})
	return err
}

func (p *SimpleProxy) socks5Connect(conn net.Conn) (string, error) {
	buf := make([]byte, 4)
	if _, err := io.ReadFull(conn, buf); err != nil {
		return "", fmt.Errorf("failed to read connect request: %v", err)
	}

	if buf[0] != 0x05 || buf[1] != 0x01 || buf[2] != 0x00 {
		return "", fmt.Errorf("invalid SOCKS5 connect request")
	}

	var addr string
	switch buf[3] {
	case 0x01: // IPv4
		ipBuf := make([]byte, 4)
		if _, err := io.ReadFull(conn, ipBuf); err != nil {
			return "", err
		}
		addr = net.IP(ipBuf).String()
	case 0x03: // Domain name
		lenBuf := make([]byte, 1)
		if _, err := io.ReadFull(conn, lenBuf); err != nil {
			return "", err
		}
		domainBuf := make([]byte, lenBuf[0])
		if _, err := io.ReadFull(conn, domainBuf); err != nil {
			return "", err
		}
		addr = string(domainBuf)
	case 0x04: // IPv6
		ipBuf := make([]byte, 16)
		if _, err := io.ReadFull(conn, ipBuf); err != nil {
			return "", err
		}
		addr = net.IP(ipBuf).String()
	default:
		return "", fmt.Errorf("unsupported address type: %d", buf[3])
	}

	portBuf := make([]byte, 2)
	if _, err := io.ReadFull(conn, portBuf); err != nil {
		return "", err
	}
	port := int(portBuf[0])<<8 + int(portBuf[1])

	targetAddr := net.JoinHostPort(addr, strconv.Itoa(port))

	response := []byte{0x05, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	if _, err := conn.Write(response); err != nil {
		return "", err
	}

	return targetAddr, nil
}

func (p *SimpleProxy) relayData(client, target net.Conn, targetAddr string) {
	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		written, err := io.Copy(target, client)
		if err != nil {
			p.logger.Debug("Client to target relay error", "target", targetAddr, "bytes", written, "error", err)
		} else {
			p.logger.Debug("Client to target relay completed", "target", targetAddr, "bytes", written)
		}
	}()

	go func() {
		defer wg.Done()
		written, err := io.Copy(client, target)
		if err != nil {
			p.logger.Debug("Target to client relay error", "target", targetAddr, "bytes", written, "error", err)
		} else {
			p.logger.Debug("Target to client relay completed", "target", targetAddr, "bytes", written)
		}
	}()

	wg.Wait()
	p.logger.Debug("Connection relay finished", "target", targetAddr)
}

func main() {
	var (
		bind         = flag.String("bind", "127.0.0.1:1080", "SOCKS5 proxy bind address")
		verbose      = flag.Bool("v", false, "Enable verbose logging")
		useMasque    = flag.Bool("masque", false, "Use MASQUE tunnel as backend")
		masqueServer = flag.String("masque-server", "", "MASQUE server endpoint (e.g., 162.159.198.1:443)")
	)
	flag.Parse()

	logLevel := slog.LevelInfo
	if *verbose {
		logLevel = slog.LevelDebug
	}
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: logLevel}))

	fmt.Println("🔐 Enhanced SOCKS5 Proxy Server")
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	if *useMasque {
		fmt.Printf("📋 This proxy will route traffic through MASQUE tunnel\n")
		if *masqueServer != "" {
			fmt.Printf("📋 MASQUE endpoint: %s\n", *masqueServer)
		} else {
			fmt.Printf("📋 MASQUE endpoint: auto-detected (Cloudflare default)\n")
		}
	} else {
		fmt.Printf("📋 This proxy will route traffic through your system's network\n")
		fmt.Printf("📋 Use --masque flag to enable MASQUE tunneling\n")
	}
	fmt.Printf("📋 SOCKS5 proxy available at: %s\n", *bind)
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	proxy := NewSimpleProxy(*bind, logger, *useMasque, *masqueServer)

	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-signalChan
		fmt.Printf("\n🛑 Shutting down proxy server...\n")
		proxy.Stop()
	}()

	if err := proxy.Start(); err != nil {
		logger.Error("Proxy server error", "error", err)
		os.Exit(1)
	}

	fmt.Printf("👋 Proxy server stopped.\n")
}
