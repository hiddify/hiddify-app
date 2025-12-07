package app

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/netip"
	"path"
	"sync"

	"github.com/bepass-org/vwarp/iputils"
	"github.com/bepass-org/vwarp/masque"
	"github.com/bepass-org/vwarp/masque/noize"
	"github.com/bepass-org/vwarp/psiphon"
	"github.com/bepass-org/vwarp/warp"
	"github.com/bepass-org/vwarp/wireguard/preflightbind"
	"github.com/bepass-org/vwarp/wireguard/tun"
	"github.com/bepass-org/vwarp/wireguard/tun/netstack"
	"github.com/bepass-org/vwarp/wiresocks"
)

const singleMTU = 1280 // MASQUE/QUIC tunnel MTU (standard MTU matching usque)
const doubleMTU = 1280 // minimum mtu for IPv6, may cause frag reassembly somewhere

type WarpOptions struct {
	Bind               netip.AddrPort
	Endpoint           string
	License            string
	DnsAddr            netip.Addr
	Psiphon            *PsiphonOptions
	Gool               bool
	Masque             bool
	MasqueAutoFallback bool   // Automatically fallback to WireGuard if MASQUE fails
	MasquePreferred    bool   // Prefer MASQUE over WireGuard when both are available
	MasqueNoize        bool   // Enable MASQUE noize obfuscation
	MasqueNoizePreset  string // Noize preset: light, medium, heavy, stealth, gfw
	MasqueNoizeConfig  string // Path to custom noize configuration JSON file
	Scan               *wiresocks.ScanOptions
	CacheDir           string
	FwMark             uint32
	WireguardConfig    string
	Reserved           string
	TestURL            string
	AtomicNoizeConfig  *preflightbind.AtomicNoizeConfig
	ProxyAddress       string
}

type PsiphonOptions struct {
	Country string
}

func RunWarp(ctx context.Context, l *slog.Logger, opts WarpOptions) error {
	if opts.WireguardConfig != "" {
		if err := runWireguard(ctx, l, opts); err != nil {
			return err
		}

		return nil
	}

	if opts.Psiphon != nil && opts.Gool {
		return errors.New("can't use psiphon and gool at the same time")
	}

	if opts.Masque && opts.Gool {
		return errors.New("can't use masque and gool at the same time")
	}

	if opts.Masque && opts.Psiphon != nil {
		return errors.New("can't use masque and psiphon at the same time")
	}

	if opts.Psiphon != nil && opts.Psiphon.Country == "" {
		return errors.New("must provide country for psiphon")
	}

	// Decide Working Scenario
	endpoints := []string{opts.Endpoint, opts.Endpoint}

	if opts.Scan != nil {
		// make primary identity
		ident, err := warp.LoadOrCreateIdentity(l, path.Join(opts.CacheDir, "primary"), opts.License)
		if err != nil {
			l.Error("couldn't load primary warp identity")
			return err
		}

		// Reading the private key from the 'Interface' section
		opts.Scan.PrivateKey = ident.PrivateKey

		// Reading the public key from the 'Peer' section
		opts.Scan.PublicKey = ident.Config.Peers[0].PublicKey

		res, err := wiresocks.RunScan(ctx, l, *opts.Scan)
		if err != nil {
			return err
		}

		l.Debug("scan results", "endpoints", res)

		endpoints = make([]string, len(res))
		for i := 0; i < len(res); i++ {
			endpoints[i] = res[i].AddrPort.String()
		}
	}
	l.Info("using warp endpoints", "endpoints", endpoints)

	var warpErr error
	switch {
	case opts.Masque:
		l.Info("running in MASQUE mode")
		// run warp through MASQUE proxy
		warpErr = runWarpWithMasque(ctx, l, opts, endpoints[0])

		// Auto-fallback to WireGuard if MASQUE fails and fallback is enabled
		if warpErr != nil && opts.MasqueAutoFallback {
			l.Warn("MASQUE connection failed, attempting WireGuard fallback", "error", warpErr)
			warpErr = runWarp(ctx, l, opts, endpoints[0])
			if warpErr == nil {
				l.Info("WireGuard fallback successful")
			}
		}
	case opts.MasquePreferred:
		// Try MASQUE first, fallback to WireGuard automatically
		l.Info("running in MASQUE-preferred mode")
		warpErr = runWarpWithMasque(ctx, l, opts, endpoints[0])

		if warpErr != nil {
			l.Warn("MASQUE preferred but failed, falling back to WireGuard", "error", warpErr)
			warpErr = runWarp(ctx, l, opts, endpoints[0])
			if warpErr == nil {
				l.Info("WireGuard fallback successful")
			}
		} else {
			l.Info("MASQUE preferred mode successful")
		}
	case opts.Psiphon != nil:
		l.Info("running in Psiphon (cfon) mode")
		// run primary warp on a random tcp port and run psiphon on bind address
		warpErr = runWarpWithPsiphon(ctx, l, opts, endpoints[0])
	case opts.Gool:
		l.Info("running in warp-in-warp (gool) mode")
		// run warp in warp
		warpErr = runWarpInWarp(ctx, l, opts, endpoints)
	default:
		l.Info("running in normal warp mode")
		// just run primary warp on bindAddress
		warpErr = runWarp(ctx, l, opts, endpoints[0])
	}

	return warpErr
}

func runWireguard(ctx context.Context, l *slog.Logger, opts WarpOptions) error {
	conf, err := wiresocks.ParseConfig(opts.WireguardConfig)
	if err != nil {
		return err
	}

	// Set up MTU
	conf.Interface.MTU = singleMTU
	// Set up DNS Address
	conf.Interface.DNS = []netip.Addr{opts.DnsAddr}

	// Enable trick and keepalive on all peers in config
	for i, peer := range conf.Peers {
		// Only enable old trick functionality if AtomicNoize is not being used
		if opts.AtomicNoizeConfig == nil {
			peer.Trick = true
		}
		peer.KeepAlive = 5

		// Try resolving if the endpoint is a domain
		addr, err := iputils.ParseResolveAddressPort(peer.Endpoint, false, opts.DnsAddr.String())
		if err == nil {
			peer.Endpoint = addr.String()
		}

		conf.Peers[i] = peer
	}

	// Establish wireguard on userspace stack
	var werr error
	var tnet *netstack.Net
	var tunDev tun.Device
	for _, t := range []string{"t1", "t2"} {
		// Create userspace tun network stack
		tunDev, tnet, werr = netstack.CreateNetTUN(conf.Interface.Addresses, conf.Interface.DNS, conf.Interface.MTU)
		if werr != nil {
			continue
		}

		werr = establishWireguard(l, conf, tunDev, opts.FwMark, t, opts.AtomicNoizeConfig, opts.ProxyAddress)
		if werr != nil {
			continue
		}

		// Test wireguard connectivity
		werr = usermodeTunTest(ctx, l, tnet, opts.TestURL)
		if werr != nil {
			continue
		}
		break
	}
	if werr != nil {
		return werr
	}

	// Run a proxy on the userspace stack
	actualBind, err := wiresocks.StartProxy(ctx, l, tnet, opts.Bind)
	if err != nil {
		return err
	}

	l.Info("serving proxy", "address", actualBind)

	return nil
}

func runWarp(ctx context.Context, l *slog.Logger, opts WarpOptions, endpoint string) error {
	// make primary identity
	ident, err := warp.LoadOrCreateIdentity(l, path.Join(opts.CacheDir, "primary"), opts.License)
	if err != nil {
		l.Error("couldn't load primary warp identity")
		return err
	}

	conf := generateWireguardConfig(ident)

	// Set up MTU
	conf.Interface.MTU = singleMTU
	// Set up DNS Address
	conf.Interface.DNS = []netip.Addr{opts.DnsAddr}

	// Enable trick and keepalive on all peers in config
	for i, peer := range conf.Peers {
		peer.Endpoint = endpoint
		// Only enable old trick functionality if AtomicNoize is not being used
		if opts.AtomicNoizeConfig == nil {
			peer.Trick = true
		}
		peer.KeepAlive = 5

		if opts.Reserved != "" {
			r, err := wiresocks.ParseReserved(opts.Reserved)
			if err != nil {
				return err
			}
			peer.Reserved = r
		}

		conf.Peers[i] = peer
	}

	// Establish wireguard on userspace stack
	var werr error
	var tnet *netstack.Net
	var tunDev tun.Device
	for _, t := range []string{"t1", "t2"} {
		tunDev, tnet, werr = netstack.CreateNetTUN(conf.Interface.Addresses, conf.Interface.DNS, conf.Interface.MTU)
		if werr != nil {
			continue
		}

		werr = establishWireguard(l, &conf, tunDev, opts.FwMark, t, opts.AtomicNoizeConfig, opts.ProxyAddress)
		if werr != nil {
			continue
		}

		// Test wireguard connectivity
		werr = usermodeTunTest(ctx, l, tnet, opts.TestURL)
		if werr != nil {
			continue
		}
		break
	}
	if werr != nil {
		return werr
	}

	// Run a proxy on the userspace stack
	actualBind, err := wiresocks.StartProxy(ctx, l, tnet, opts.Bind)
	if err != nil {
		return err
	}

	l.Info("serving proxy", "address", actualBind)
	return nil
}

func runWarpInWarp(ctx context.Context, l *slog.Logger, opts WarpOptions, endpoints []string) error {
	// make primary identity
	ident1, err := warp.LoadOrCreateIdentity(l, path.Join(opts.CacheDir, "primary"), opts.License)
	if err != nil {
		l.Error("couldn't load primary warp identity")
		return err
	}

	conf := generateWireguardConfig(ident1)

	// Set up MTU
	conf.Interface.MTU = singleMTU
	// Set up DNS Address
	conf.Interface.DNS = []netip.Addr{opts.DnsAddr}

	// Enable trick and keepalive on all peers in config
	for i, peer := range conf.Peers {
		peer.Endpoint = endpoints[0]
		// Only enable old trick functionality if AtomicNoize is not being used
		if opts.AtomicNoizeConfig == nil {
			peer.Trick = true
		}
		peer.KeepAlive = 5

		if opts.Reserved != "" {
			r, err := wiresocks.ParseReserved(opts.Reserved)
			if err != nil {
				return err
			}
			peer.Reserved = r
		}

		conf.Peers[i] = peer
	}

	// Establish wireguard on userspace stack and bind the wireguard sockets to the default interface and apply
	var werr error
	var tnet1 *netstack.Net
	var tunDev tun.Device
	for _, t := range []string{"t1", "t2"} {
		// Create userspace tun network stack
		tunDev, tnet1, werr = netstack.CreateNetTUN(conf.Interface.Addresses, conf.Interface.DNS, conf.Interface.MTU)
		if werr != nil {
			continue
		}

		werr = establishWireguard(l.With("gool", "outer"), &conf, tunDev, opts.FwMark, t, opts.AtomicNoizeConfig, opts.ProxyAddress)
		if werr != nil {
			continue
		}

		// Test wireguard connectivity
		werr = usermodeTunTest(ctx, l, tnet1, opts.TestURL)
		if werr != nil {
			continue
		}
		break
	}
	if werr != nil {
		return werr
	}

	// Create a UDP port forward between localhost and the remote endpoint
	addr, err := wiresocks.NewVtunUDPForwarder(ctx, netip.MustParseAddrPort("127.0.0.1:0"), endpoints[0], tnet1, singleMTU)
	if err != nil {
		return err
	}

	// make secondary
	ident2, err := warp.LoadOrCreateIdentity(l, path.Join(opts.CacheDir, "secondary"), opts.License)
	if err != nil {
		l.Error("couldn't load secondary warp identity")
		return err
	}

	conf = generateWireguardConfig(ident2)

	// Set up MTU
	conf.Interface.MTU = doubleMTU
	// Set up DNS Address
	conf.Interface.DNS = []netip.Addr{opts.DnsAddr}

	// Enable keepalive on all peers in config
	for i, peer := range conf.Peers {
		peer.Endpoint = addr.String()
		peer.KeepAlive = 20

		if opts.Reserved != "" {
			r, err := wiresocks.ParseReserved(opts.Reserved)
			if err != nil {
				return err
			}
			peer.Reserved = r
		}

		conf.Peers[i] = peer
	}

	// Create userspace tun network stack
	tunDev, tnet2, err := netstack.CreateNetTUN(conf.Interface.Addresses, conf.Interface.DNS, conf.Interface.MTU)
	if err != nil {
		return err
	}

	// Establish wireguard on userspace stack
	if err := establishWireguard(l.With("gool", "inner"), &conf, tunDev, opts.FwMark, "t0", nil, ""); err != nil {
		return err
	}

	// Test wireguard connectivity
	if err := usermodeTunTest(ctx, l, tnet2, opts.TestURL); err != nil {
		return err
	}

	actualBind, err := wiresocks.StartProxy(ctx, l, tnet2, opts.Bind)
	if err != nil {
		return err
	}

	l.Info("serving proxy", "address", actualBind)
	return nil
}

func runWarpWithPsiphon(ctx context.Context, l *slog.Logger, opts WarpOptions, endpoint string) error {
	// make primary identity
	ident, err := warp.LoadOrCreateIdentity(l, path.Join(opts.CacheDir, "primary"), opts.License)
	if err != nil {
		l.Error("couldn't load primary warp identity")
		return err
	}

	conf := generateWireguardConfig(ident)

	// Set up MTU
	conf.Interface.MTU = singleMTU
	// Set up DNS Address
	conf.Interface.DNS = []netip.Addr{opts.DnsAddr}

	// Enable trick and keepalive on all peers in config
	for i, peer := range conf.Peers {
		peer.Endpoint = endpoint
		// Only enable old trick functionality if AtomicNoize is not being used
		if opts.AtomicNoizeConfig == nil {
			peer.Trick = true
		}
		peer.KeepAlive = 5

		if opts.Reserved != "" {
			r, err := wiresocks.ParseReserved(opts.Reserved)
			if err != nil {
				return err
			}
			peer.Reserved = r
		}

		conf.Peers[i] = peer
	}

	// Establish wireguard on userspace stack
	var werr error
	var tnet *netstack.Net
	var tunDev tun.Device
	for _, t := range []string{"t1", "t2"} {
		// Create userspace tun network stack
		tunDev, tnet, werr = netstack.CreateNetTUN(conf.Interface.Addresses, conf.Interface.DNS, conf.Interface.MTU)
		if werr != nil {
			continue
		}

		werr = establishWireguard(l, &conf, tunDev, opts.FwMark, t, opts.AtomicNoizeConfig, opts.ProxyAddress)
		if werr != nil {
			continue
		}

		// Test wireguard connectivity
		werr = usermodeTunTest(ctx, l, tnet, opts.TestURL)
		if werr != nil {
			continue
		}
		break
	}
	if werr != nil {
		return werr
	}

	// Run a proxy on the userspace stack
	warpBind, err := wiresocks.StartProxy(ctx, l, tnet, netip.MustParseAddrPort("127.0.0.1:0"))
	if err != nil {
		return err
	}

	// run psiphon
	err = psiphon.RunPsiphon(ctx, l.With("subsystem", "psiphon"), warpBind, opts.CacheDir, opts.Bind, opts.Psiphon.Country)
	if err != nil {
		return fmt.Errorf("unable to run psiphon %w", err)
	}

	l.Info("serving proxy", "address", opts.Bind)
	return nil
}

func runWarpWithMasque(ctx context.Context, l *slog.Logger, opts WarpOptions, endpoint string) error {
	l.Info("running in MASQUE mode")

	// Check network MTU compatibility for MASQUE
	iputils.DetectAndCheckMTUForMasque(l)

	// Convert endpoint to MASQUE endpoint (port 443)
	// The endpoint may be from scanner (port 2408) or user-provided (any port)
	var masqueEndpoint string
	l.Info("using endpoint as MASQUE server", "endpoint", endpoint)
	if host, _, err := net.SplitHostPort(endpoint); err == nil {
		// Successfully split, use the host with port 443
		masqueEndpoint = net.JoinHostPort(host, "443")
		l.Debug("Converted endpoint to MASQUE endpoint", "from", endpoint, "to", masqueEndpoint)
	} else {
		// No port specified, assume it's just a host, add port 443
		masqueEndpoint = net.JoinHostPort(endpoint, "443")
		l.Debug("Added MASQUE port to endpoint", "from", endpoint, "to", masqueEndpoint)
	}

	// Create MASQUE adapter using usque library
	masqueConfigPath := path.Join(opts.CacheDir, "masque_config.json")
	l.Debug("Creating MASQUE adapter", "masqueEndpoint", masqueEndpoint, "configPath", masqueConfigPath)

	// Configure noize obfuscation if enabled
	var noizeConfig *noize.NoizeConfig
	if opts.MasqueNoize {
		// Check for custom config file first
		if opts.MasqueNoizeConfig != "" {
			l.Info("Loading custom MASQUE noize configuration", "configPath", opts.MasqueNoizeConfig)
			customConfig, err := noize.LoadConfigFromFile(opts.MasqueNoizeConfig)
			if err != nil {
				l.Warn("Failed to load custom noize config, falling back to preset", "error", err, "preset", opts.MasqueNoizePreset)
			} else {
				noizeConfig = customConfig
				l.Info("Custom noize configuration loaded successfully")
			}
		}

		// Use preset if no custom config loaded
		if noizeConfig == nil {
			preset := opts.MasqueNoizePreset
			if preset == "" {
				preset = "medium"
			}

			l.Info("Using MASQUE noize preset configuration", "preset", preset)

			switch preset {
			case "minimal":
				noizeConfig = noize.MinimalObfuscationConfig()
			case "light":
				noizeConfig = noize.LightObfuscationConfig()
			case "medium":
				noizeConfig = noize.MediumObfuscationConfig()
			case "heavy":
				noizeConfig = noize.HeavyObfuscationConfig()
			case "stealth":
				noizeConfig = noize.StealthObfuscationConfig()
			case "gfw":
				noizeConfig = noize.GFWBypassConfig()
			case "firewall":
				noizeConfig = noize.FirewallBypassConfig()
			case "none":
				noizeConfig = nil
				l.Info("Noize disabled (preset=none)")
			default:
				l.Warn("Unknown noize preset, using medium", "preset", preset)
				noizeConfig = noize.MediumObfuscationConfig()
			}
		}
	}

	adapter, err := masque.NewMasqueAdapter(ctx, masque.AdapterConfig{
		ConfigPath:  masqueConfigPath,
		DeviceName:  "vwarp-masque",
		Endpoint:    masqueEndpoint,
		Logger:      l,
		License:     opts.License,
		NoizeConfig: noizeConfig,
	})
	if err != nil {
		return fmt.Errorf("failed to establish MASQUE connection: %w", err)
	}
	defer adapter.Close()

	l.Info("MASQUE tunnel established successfully")

	// Get tunnel addresses
	ipv4, ipv6 := adapter.GetLocalAddresses()
	l.Info("MASQUE tunnel addresses", "ipv4", ipv4, "ipv6", ipv6)

	// Create TUN device configuration for the MASQUE tunnel
	tunAddresses := []netip.Addr{}
	if ipv4 != "" {
		if addr, err := netip.ParseAddr(ipv4); err == nil {
			tunAddresses = append(tunAddresses, addr)
		}
	}
	if ipv6 != "" {
		if addr, err := netip.ParseAddr(ipv6); err == nil {
			tunAddresses = append(tunAddresses, addr)
		}
	}

	if len(tunAddresses) == 0 {
		return errors.New("no valid tunnel addresses received from MASQUE")
	}

	// Use DNS servers - respect user's choice
	dnsServers := []netip.Addr{opts.DnsAddr}

	// Create netstack TUN
	tunDev, tnet, err := netstack.CreateNetTUN(tunAddresses, dnsServers, singleMTU)
	if err != nil {
		return fmt.Errorf("failed to create netstack: %w", err)
	}

	l.Info("netstack created on MASQUE tunnel")

	// Create adapter for the netstack device
	tunAdapter := &netstackTunAdapter{
		dev:             tunDev,
		tunnelBufPool:   &sync.Pool{New: func() interface{} { buf := make([][]byte, 1); return &buf }},
		tunnelSizesPool: &sync.Pool{New: func() interface{} { sizes := make([]int, 1); return &sizes }},
	}

	// Create adapter factory for reconnection
	adapterFactory := func() (*masque.MasqueAdapter, error) {
		l.Info("Recreating MASQUE adapter with fresh configuration")
		return masque.NewMasqueAdapter(ctx, masque.AdapterConfig{
			ConfigPath:  masqueConfigPath,
			DeviceName:  "vwarp-masque",
			Endpoint:    masqueEndpoint,
			Logger:      l,
			License:     opts.License,
			NoizeConfig: noizeConfig,
		})
	}

	// Start tunnel maintenance goroutine
	go maintainMasqueTunnel(ctx, l, adapter, adapterFactory, tunAdapter, singleMTU)

	// Test connectivity
	if err := usermodeTunTest(ctx, l, tnet, opts.TestURL); err != nil {
		l.Warn("connectivity test failed", "error", err)
		// Don't fail completely, just warn
	} else {
		l.Info("MASQUE connectivity test passed")
	}

	// Start SOCKS proxy on the netstack
	actualBind, err := wiresocks.StartProxy(ctx, l, tnet, opts.Bind)
	if err != nil {
		return fmt.Errorf("failed to start proxy: %w", err)
	}

	l.Info("serving proxy via MASQUE tunnel", "address", actualBind)

	// Keep running until context is cancelled
	<-ctx.Done()
	return nil
}

func generateWireguardConfig(i *warp.Identity) wiresocks.Configuration {
	priv, _ := wiresocks.EncodeBase64ToHex(i.PrivateKey)
	pub, _ := wiresocks.EncodeBase64ToHex(i.Config.Peers[0].PublicKey)
	clientID, _ := base64.StdEncoding.DecodeString(i.Config.ClientID)
	return wiresocks.Configuration{
		Interface: &wiresocks.InterfaceConfig{
			PrivateKey: priv,
			Addresses: []netip.Addr{
				netip.MustParseAddr(i.Config.Interface.Addresses.V4),
				netip.MustParseAddr(i.Config.Interface.Addresses.V6),
			},
		},
		Peers: []wiresocks.PeerConfig{{
			PublicKey:    pub,
			PreSharedKey: "0000000000000000000000000000000000000000000000000000000000000000",
			AllowedIPs: []netip.Prefix{
				netip.MustParsePrefix("0.0.0.0/0"),
				netip.MustParsePrefix("::/0"),
			},
			Endpoint: i.Config.Peers[0].Endpoint.Host,
			Reserved: [3]byte{clientID[0], clientID[1], clientID[2]},
		}},
	}
}
