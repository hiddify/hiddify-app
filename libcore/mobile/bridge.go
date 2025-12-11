package main

import "C"

import (
	"context"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/GFW-knocker/Xray-core/core"
	feature_stats "github.com/GFW-knocker/Xray-core/features/stats"
	_ "github.com/GFW-knocker/Xray-core/main/distro/all"
	"golang.org/x/net/proxy"
)

var (
	server *core.Instance
	mu     sync.Mutex
)

//export Start
func Start(configStr *C.char) *C.char {
	mu.Lock()
	defer mu.Unlock()

	if server != nil {
		return C.CString("Core already running")
	}

	// Set asset location if needed, usually defaults to executable dir or env 'xray.location.asset'
	// For android, assets might be tricky.
	// For now we assume config is self-contained or assets are in env.
	assetPath := os.Getenv("XRAY_LOCATION_ASSET")
	if assetPath == "" {
		// Fallback or ignore
	}

	confJson := C.GoString(configStr)

	// LoadConfig with "json" format
	// standard Xray distribution registers "json" loader.
	config, err := core.LoadConfig("json", strings.NewReader(confJson))
	if err != nil {
		log.Printf("Failed to load config: %v", err)
		return C.CString("Failed to load config: " + err.Error())
	}

	inst, err := core.New(config)
	if err != nil {
		log.Printf("Failed to create instance: %v", err)
		return C.CString("Failed to create instance: " + err.Error())
	}

	if err := inst.Start(); err != nil {
		log.Printf("Failed to start instance: %v", err)
		return C.CString("Failed to start instance: " + err.Error())
	}

	server = inst
	log.Println("Xray Core started successfully")
	return nil
}

//export Stop
func Stop() {
	mu.Lock()
	defer mu.Unlock()
	if server != nil {
		server.Close()
		server = nil
		log.Println("Xray Core stopped")
	}
}

//export IsRunning
func IsRunning() C.int {
	mu.Lock()
	defer mu.Unlock()
	if server != nil {
		return 1
	}
	return 0
}

// Ping tests direct TCP connection to server (without proxy)
// Returns latency in milliseconds, or -1 on error
//
//export Ping
func Ping(address *C.char, timeoutMs C.int) C.int {
	addr := C.GoString(address)
	timeout := time.Duration(int(timeoutMs)) * time.Millisecond

	start := time.Now()
	conn, err := net.DialTimeout("tcp", addr, timeout)
	if err != nil {
		log.Printf("Ping failed to %s: %v", addr, err)
		return -1
	}
	defer conn.Close()

	latency := time.Since(start).Milliseconds()
	return C.int(latency)
}

//export ProxyPing
func ProxyPing(socksAddr *C.char, testUrl *C.char, timeoutMs C.int) C.int {
	socks := C.GoString(socksAddr)
	url := C.GoString(testUrl)
	timeout := time.Duration(int(timeoutMs)) * time.Millisecond

	// Create SOCKS5 dialer
	dialer, err := proxy.SOCKS5("tcp", socks, nil, proxy.Direct)
	if err != nil {
		log.Printf("ProxyPing failed to create dialer: %v", err)
		return -1
	}

	// Create HTTP client with SOCKS5 proxy
	httpClient := &http.Client{
		Transport: &http.Transport{
			DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
				return dialer.Dial(network, addr)
			},
		},
		Timeout: timeout,
	}

	start := time.Now()
	resp, err := httpClient.Get(url)
	if err != nil {
		log.Printf("ProxyPing failed to %s via %s: %v", url, socks, err)
		return -1
	}
	defer resp.Body.Close()

	latency := time.Since(start).Milliseconds()
	return C.int(latency)
}

// Traffic stats tracking
var (
	totalUplink   int64
	totalDownlink int64
	statsMu       sync.Mutex
)

// GetUplink returns total uplink bytes and resets counter
//
//export GetUplink
func GetUplink() C.longlong {
	mu.Lock()
	defer mu.Unlock()

	if server == nil {
		return 0
	}

	// Try to get stats from Xray's stats feature
	statsManager := server.GetFeature(feature_stats.ManagerType())
	if statsManager == nil {
		return 0
	}

	manager, ok := statsManager.(feature_stats.Manager)
	if !ok {
		return 0
	}

	counter := manager.GetCounter("outbound>>>proxy>>>traffic>>>uplink")
	if counter == nil {
		return 0
	}

	// Reset and return value
	return C.longlong(counter.Set(0))
}

// GetDownlink returns total downlink bytes and resets counter
//
//export GetDownlink
func GetDownlink() C.longlong {
	mu.Lock()
	defer mu.Unlock()

	if server == nil {
		return 0
	}

	// Try to get stats from Xray's stats feature
	statsManager := server.GetFeature(feature_stats.ManagerType())
	if statsManager == nil {
		return 0
	}

	manager, ok := statsManager.(feature_stats.Manager)
	if !ok {
		return 0
	}

	counter := manager.GetCounter("outbound>>>proxy>>>traffic>>>downlink")
	if counter == nil {
		return 0
	}

	// Reset and return value
	return C.longlong(counter.Set(0))
}

func main() {}
