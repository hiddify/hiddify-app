package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/netip"
	"os"
	"path"
	"time"

	"github.com/adrg/xdg"
	"github.com/bepass-org/vwarp/app"
	p "github.com/bepass-org/vwarp/psiphon"
	"github.com/bepass-org/vwarp/warp"
	"github.com/bepass-org/vwarp/wireguard/preflightbind"
	"github.com/bepass-org/vwarp/wiresocks"
	"github.com/peterbourgon/ff/v4"
	"github.com/peterbourgon/ff/v4/ffval"
)

type rootConfig struct {
	flags   *ff.FlagSet
	command *ff.Command

	verbose            bool
	v4                 bool
	v6                 bool
	bind               string
	endpoint           string
	key                string
	dns                string
	gool               bool
	psiphon            bool
	masque             bool
	masqueAutoFallback bool
	masquePreferred    bool
	country            string
	scan               bool
	rtt                time.Duration
	cacheDir           string
	fwmark             uint32
	reserved           string
	wgConf             string
	testUrl            string
	config             string

	// AtomicNoize WireGuard configuration
	AtomicNoizeEnable         bool
	AtomicNoizeI1             string
	AtomicNoizeI2             string
	AtomicNoizeI3             string
	AtomicNoizeI4             string
	AtomicNoizeI5             string
	AtomicNoizeS1             int
	AtomicNoizeS2             int
	AtomicNoizeJc             int
	AtomicNoizeJmin           int
	AtomicNoizeJmax           int
	AtomicNoizeJcAfterI1      int
	AtomicNoizeJcBeforeHS     int
	AtomicNoizeJcAfterHS      int
	AtomicNoizeJunkInterval   time.Duration
	AtomicNoizeAllowZeroSize  bool
	AtomicNoizeHandshakeDelay time.Duration

	// MASQUE Noize configuration
	masqueNoize       bool
	masqueNoizePreset string
	masqueNoizeConfig string // Path to custom noize config JSON file

	// SOCKS proxy configuration
	proxyAddress string
}

func newRootCmd() *rootConfig {
	var cfg rootConfig
	cfg.flags = ff.NewFlagSet(appName)
	cfg.flags.AddFlag(ff.FlagConfig{
		ShortName: 'v',
		LongName:  "verbose",
		Value:     ffval.NewValueDefault(&cfg.verbose, false),
		Usage:     "enable verbose logging",
		NoDefault: true,
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		ShortName: '4',
		LongName:  "ipv4",
		Value:     ffval.NewValueDefault(&cfg.v4, false),
		Usage:     "only use IPv4 for random warp/MASQUE endpoint",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		ShortName: '6',
		Value:     ffval.NewValueDefault(&cfg.v6, false),
		Usage:     "only use IPv6 for random warp endpoint",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		ShortName: 'b',
		LongName:  "bind",
		Value:     ffval.NewValueDefault(&cfg.bind, "127.0.0.1:8086"),
		Usage:     "socks bind address",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		ShortName: 'e',
		LongName:  "endpoint",
		Value:     ffval.NewValueDefault(&cfg.endpoint, ""),
		Usage:     "warp endpoint",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		ShortName: 'k',
		LongName:  "key",
		Value:     ffval.NewValueDefault(&cfg.key, ""),
		Usage:     "warp key",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "dns",
		Value:    ffval.NewValueDefault(&cfg.dns, "1.1.1.1"),
		Usage:    "DNS address",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "gool",
		Value:    ffval.NewValueDefault(&cfg.gool, false),
		Usage:    "enable gool mode (warp in warp)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "masque",
		Value:    ffval.NewValueDefault(&cfg.masque, false),
		Usage:    "enable MASQUE mode (connect to warp via MASQUE proxy)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "masque-auto-fallback",
		Value:    ffval.NewValueDefault(&cfg.masqueAutoFallback, false),
		Usage:    "automatically fallback to WireGuard if MASQUE fails",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "masque-preferred",
		Value:    ffval.NewValueDefault(&cfg.masquePreferred, false),
		Usage:    "prefer MASQUE over WireGuard (with automatic fallback)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "masque-noize",
		Value:    ffval.NewValueDefault(&cfg.masqueNoize, false),
		Usage:    "enable MASQUE QUIC obfuscation (helps bypass DPI/censorship)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "masque-noize-preset",
		Value:    ffval.NewValueDefault(&cfg.masqueNoizePreset, "medium"),
		Usage:    "MASQUE noize preset: light, medium, heavy, stealth, gfw, firewall (default: medium)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "masque-noize-config",
		Value:    ffval.NewValueDefault(&cfg.masqueNoizeConfig, ""),
		Usage:    "path to custom MASQUE noize configuration JSON file (overrides preset)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "cfon",
		Value:    ffval.NewValueDefault(&cfg.psiphon, false),
		Usage:    "enable psiphon mode (must provide country as well)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "country",
		Value:    ffval.NewEnum(&cfg.country, p.Countries...),
		Usage:    "psiphon country code",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "scan",
		Value:    ffval.NewValueDefault(&cfg.scan, false),
		Usage:    "enable warp scanning",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "rtt",
		Value:    ffval.NewValueDefault(&cfg.rtt, 1000*time.Millisecond),
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "cache-dir",
		Value:    ffval.NewValueDefault(&cfg.cacheDir, ""),
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "fwmark",
		Value:    ffval.NewValueDefault(&cfg.fwmark, 0x0),
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "reserved",
		Value:    ffval.NewValueDefault(&cfg.reserved, ""),
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "wgconf",
		Value:    ffval.NewValueDefault(&cfg.wgConf, ""),
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "test-url",
		Value:    ffval.NewValueDefault(&cfg.testUrl, "http://connectivity.cloudflareclient.com/cdn-cgi/trace"),
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		ShortName: 'c',
		LongName:  "config",
		Value:     ffval.NewValueDefault(&cfg.config, ""),
	})

	// AtomicNoize WireGuard flags
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-enable",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeEnable, false),
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-i1",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeI1, ""),
		Usage:    "AtomicNoize I1 signature packet in CPS format (e.g., '<b 0xc200...>'). Required for obfuscation.",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-i2",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeI2, "1"),
		Usage:    "AtomicNoize I2 signature packet (CPS format or simple number)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-i3",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeI3, "2"),
		Usage:    "AtomicNoize I3 signature packet (CPS format or simple number)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-i4",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeI4, "3"),
		Usage:    "AtomicNoize I4 signature packet (CPS format or simple number)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-i5",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeI5, "4"),
		Usage:    "AtomicNoize I5 signature packet (CPS format or simple number)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-s1",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeS1, 0),
		Usage:    "AtomicNoize S1 random prefix for Init packets (0-64 bytes) - disabled for WARP compatibility",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-s2",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeS2, 0),
		Usage:    "AtomicNoize S2 random prefix for Response packets (0-64 bytes) - disabled for WARP compatibility",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-jc",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeJc, 4),
		Usage:    "Total number of junk packets to send (0-128)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-jmin",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeJmin, 40),
		Usage:    "Minimum junk packet size in bytes",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-jmax",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeJmax, 70),
		Usage:    "Maximum junk packet size in bytes",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-jc-after-i1",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeJcAfterI1, 0),
		Usage:    "Number of junk packets to send immediately after I1 packet",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-jc-before-hs",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeJcBeforeHS, 0),
		Usage:    "Number of junk packets to send before handshake initiation",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-jc-after-hs",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeJcAfterHS, 0),
		Usage:    "Number of junk packets to send after handshake (auto-calculated as Jc - JcBeforeHS - JcAfterI1)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-junk-interval",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeJunkInterval, 10*time.Millisecond),
		Usage:    "Time interval between sending junk packets (e.g., 10ms, 50ms)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-allow-zero-size",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeAllowZeroSize, false),
		Usage:    "Allow zero-size junk packets (may not work with all UDP implementations)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "atomicnoize-handshake-delay",
		Value:    ffval.NewValueDefault(&cfg.AtomicNoizeHandshakeDelay, 0*time.Millisecond),
		Usage:    "Delay before actual WireGuard handshake after I-sequence (e.g., 50ms, 100ms)",
	})
	cfg.flags.AddFlag(ff.FlagConfig{
		LongName: "proxy",
		Value:    ffval.NewValueDefault(&cfg.proxyAddress, ""),
		Usage:    "SOCKS5 proxy address to route WireGuard traffic through (e.g., socks5://127.0.0.1:1080)",
	})
	cfg.command = &ff.Command{
		Name:  appName,
		Flags: cfg.flags,
		Exec:  cfg.exec,
	}
	return &cfg
}

func (c *rootConfig) exec(ctx context.Context, args []string) error {
	l := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))

	if c.verbose {
		l = slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelDebug}))
	}

	if c.psiphon && c.gool {
		fatal(l, errors.New("can't use cfon and gool at the same time"))
	}

	if c.masque && c.gool {
		fatal(l, errors.New("can't use masque and gool at the same time"))
	}

	if c.masque && c.psiphon {
		fatal(l, errors.New("can't use masque and cfon at the same time"))
	}

	if c.masque && c.masquePreferred {
		fatal(l, errors.New("can't use masque and masque-preferred at the same time"))
	}

	if c.masqueAutoFallback && !c.masque {
		fatal(l, errors.New("masque-auto-fallback requires masque mode to be enabled"))
	}

	if c.masquePreferred && c.gool {
		fatal(l, errors.New("can't use masque-preferred and gool at the same time"))
	}

	if c.masquePreferred && c.psiphon {
		fatal(l, errors.New("can't use masque-preferred and cfon at the same time"))
	}

	if c.masque && c.endpoint == "" {
		// If no endpoint is provided in MASQUE mode, scan for one
		l.Info("no endpoint specified, scanning for endpoints...")
		c.scan = true
	}

	if c.v4 && c.v6 {
		fatal(l, errors.New("can't force v4 and v6 at the same time"))
	}

	if !c.v4 && !c.v6 {
		c.v4, c.v6 = true, true
	}

	bindAddrPort, err := netip.ParseAddrPort(c.bind)
	if err != nil {
		fatal(l, fmt.Errorf("invalid bind address: %w", err))
	}

	dnsAddr, err := netip.ParseAddr(c.dns)
	if err != nil {
		fatal(l, fmt.Errorf("invalid DNS address: %w", err))
	}

	opts := app.WarpOptions{
		Bind:               bindAddrPort,
		Endpoint:           c.endpoint,
		License:            c.key,
		DnsAddr:            dnsAddr,
		Gool:               c.gool,
		Masque:             c.masque,
		MasqueAutoFallback: c.masqueAutoFallback,
		MasquePreferred:    c.masquePreferred,
		MasqueNoize:        c.masqueNoize,
		MasqueNoizePreset:  c.masqueNoizePreset,
		MasqueNoizeConfig:  c.masqueNoizeConfig,
		FwMark:             c.fwmark,
		WireguardConfig:    c.wgConf,
		Reserved:           c.reserved,
		TestURL:            c.testUrl,
		AtomicNoizeConfig:  c.buildAtomicNoizeConfig(),
		ProxyAddress:       c.proxyAddress,
	}

	switch {
	case c.cacheDir != "":
		opts.CacheDir = c.cacheDir
	case xdg.CacheHome != "":
		opts.CacheDir = path.Join(xdg.CacheHome, appName)
	case os.Getenv("HOME") != "":
		opts.CacheDir = path.Join(os.Getenv("HOME"), ".cache", appName)
	default:
		opts.CacheDir = "warp_plus_cache"
	}

	if c.psiphon {
		l.Info("psiphon mode enabled", "country", c.country)
		opts.Psiphon = &app.PsiphonOptions{Country: c.country}
	}

	if c.scan {
		l.Info("scanner mode enabled", "max-rtt", c.rtt)
		opts.Scan = &wiresocks.ScanOptions{V4: c.v4, V6: c.v6, MaxRTT: c.rtt}
	}

	// If the endpoint is not set, choose a random endpoint
	if opts.Endpoint == "" {
		var addrPort netip.AddrPort
		var err error

		// Use WireGuard endpoints for both WARP and MASQUE scanning
		// MASQUE will convert port 2408 -> 443 in runWarpWithMasque
		addrPort, err = warp.RandomWarpEndpoint(c.v4, c.v6)

		if err != nil {
			fatal(l, err)
		}
		opts.Endpoint = addrPort.String()
	}

	go func() {
		if err := app.RunWarp(ctx, l, opts); err != nil {
			fatal(l, err)
		}
	}()

	<-ctx.Done()

	return nil
}

// buildAtomicNoizeConfig creates an AtomicNoizeConfig from the CLI flags
func (c *rootConfig) buildAtomicNoizeConfig() *preflightbind.AtomicNoizeConfig {
	// Only create config if AtomicNoize is explicitly enabled
	if !c.AtomicNoizeEnable {
		return nil
	}

	return &preflightbind.AtomicNoizeConfig{
		I1:             c.AtomicNoizeI1,
		I2:             c.AtomicNoizeI2,
		I3:             c.AtomicNoizeI3,
		I4:             c.AtomicNoizeI4,
		I5:             c.AtomicNoizeI5,
		S1:             c.AtomicNoizeS1,
		S2:             c.AtomicNoizeS2,
		Jc:             c.AtomicNoizeJc,
		Jmin:           c.AtomicNoizeJmin,
		Jmax:           c.AtomicNoizeJmax,
		JcAfterI1:      c.AtomicNoizeJcAfterI1,
		JcBeforeHS:     c.AtomicNoizeJcBeforeHS,
		JcAfterHS:      c.AtomicNoizeJcAfterHS,
		JunkInterval:   c.AtomicNoizeJunkInterval,
		AllowZeroSize:  c.AtomicNoizeAllowZeroSize,
		HandshakeDelay: c.AtomicNoizeHandshakeDelay,
	}
}
