package main

import "C"

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/netip"
	"os"
	"sync"
	"time"

	"github.com/bepass-org/vwarp/app"
	"github.com/bepass-org/vwarp/wiresocks"
)

var (
	ctx    context.Context
	cancel context.CancelFunc
	mu     sync.Mutex
)

//export Start
func Start(configJson *C.char) *C.char {
	mu.Lock()
	defer mu.Unlock()

	if cancel != nil {
		cancel()
	}

	configStr := C.GoString(configJson)
	var config ConfigDTO
	if err := json.Unmarshal([]byte(configStr), &config); err != nil {
		return C.CString("json error: " + err.Error())
	}

	appOpts, err := config.ToWarpOptions()
	if err != nil {
		return C.CString("config error: " + err.Error())
	}

	ctx, cancel = context.WithCancel(context.Background())

	// Use generic logger capturing stdout/stderr
	l := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	if config.Verbose {
		l = slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
			Level: slog.LevelDebug,
		}))
	}

	go func() {
		defer func() {
			if r := recover(); r != nil {
				l.Error("Panic recovered", "error", r)
			}
		}()
		if err := app.RunWarp(ctx, l, appOpts); err != nil {
			if err != context.Canceled {
				l.Error("Warp running error", "error", err)
			}
		}
	}()

	return nil
}

//export Stop
func Stop() {
	mu.Lock()
	defer mu.Unlock()
	if cancel != nil {
		cancel()
		cancel = nil
	}
}

type ConfigDTO struct {
	Bind               string `json:"bind"`
	Endpoint           string `json:"endpoint"`
	License            string `json:"license"`
	DnsAddr            string `json:"dns_addr"`
	Gool               bool   `json:"gool"`
	Masque             bool   `json:"masque"`
	MasqueAutoFallback bool   `json:"masque_auto_fallback"`
	MasquePreferred    bool   `json:"masque_preferred"`
	MasqueNoize        bool   `json:"masque_noize"`
	MasqueNoizePreset  string `json:"masque_noize_preset"`
	MasqueNoizeConfig  string `json:"masque_noize_config"`
	Verbose            bool   `json:"verbose"`
	PsiphonCountry     string `json:"psiphon_country"`
	ProxyAddress       string `json:"proxy_address"`
	CacheDir           string `json:"cache_dir"`
	TestURL            string `json:"test_url"`
	Scan               bool   `json:"scan"`
	Rtt                int64  `json:"rtt"` // Milliseconds
}

func (c *ConfigDTO) ToWarpOptions() (app.WarpOptions, error) {
	bindVal, err := netip.ParseAddrPort(c.Bind)
	if err != nil {
		if c.Bind == "" {
			bindVal = netip.MustParseAddrPort("127.0.0.1:0")
		} else {
			return app.WarpOptions{}, err
		}
	}

	dnsAddr, err := netip.ParseAddr(c.DnsAddr)
	if err != nil {
		// Default to 1.1.1.1 if invalid or empty
		dnsAddr = netip.MustParseAddr("1.1.1.1")
	}

	opts := app.WarpOptions{
		Bind:               bindVal,
		Endpoint:           c.Endpoint,
		License:            c.License,
		DnsAddr:            dnsAddr,
		Gool:               c.Gool,
		Masque:             c.Masque,
		MasqueAutoFallback: c.MasqueAutoFallback,
		MasquePreferred:    c.MasquePreferred,
		MasqueNoize:        c.MasqueNoize,
		MasqueNoizePreset:  c.MasqueNoizePreset,
		MasqueNoizeConfig:  c.MasqueNoizeConfig,
		ProxyAddress:       c.ProxyAddress,
		CacheDir:           c.CacheDir,
		TestURL:            c.TestURL,
	}

	if c.PsiphonCountry != "" {
		opts.Psiphon = &app.PsiphonOptions{Country: c.PsiphonCountry}
	}

	if c.Scan {
		rtt := time.Duration(c.Rtt) * time.Millisecond
		if rtt == 0 {
			rtt = 1000 * time.Millisecond
		}
		// Assuming generic defaults for scan V4/V6 if not specified (will be handled by defaults)
		// But ScanOptions struct requires V4/V6. We didn't expose them in DTO yet, maybe default true?
		opts.Scan = &wiresocks.ScanOptions{V4: true, V6: true, MaxRTT: rtt}
	}

	return opts, nil
}

func main() {}
