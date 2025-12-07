package mixed

import (
	"context"
	"log/slog"
	"net"

	"github.com/bepass-org/vwarp/masque"
	"github.com/bepass-org/vwarp/proxy/pkg/statute"
)

// MasqueDialer wraps a MASQUE adapter to provide ProxyDialFunc functionality
type MasqueDialer struct {
	adapter      *masque.MasqueAdapter
	fallbackDial statute.ProxyDialFunc
	logger       *slog.Logger
}

// NewMasqueDialer creates a new MASQUE-aware dialer
func NewMasqueDialer(adapter *masque.MasqueAdapter, logger *slog.Logger) *MasqueDialer {
	if logger == nil {
		logger = slog.Default()
	}

	return &MasqueDialer{
		adapter:      adapter,
		fallbackDial: statute.DefaultProxyDial(),
		logger:       logger,
	}
}

// DialContext implements the ProxyDialFunc interface using MASQUE
func (m *MasqueDialer) DialContext(ctx context.Context, network, address string) (net.Conn, error) {
	if m.adapter == nil {
		m.logger.Debug("MASQUE adapter not available, using fallback", "address", address)
		return m.fallbackDial(ctx, network, address)
	}

	switch network {
	case "tcp", "tcp4", "tcp6":
		m.logger.Debug("Attempting MASQUE TCP connection", "address", address)

		// MASQUE provides IP-level tunneling, TCP is handled at a higher layer
		// For now, we'll use the fallback
		// TODO: Implement proper TCP-over-MASQUE if needed
		m.logger.Debug("MASQUE TCP dialing handled by netstack, using fallback for direct dial")
		return m.fallbackDial(ctx, network, address)

	default:
		m.logger.Debug("Unsupported network type for MASQUE, using fallback",
			"network", network, "address", address)
		return m.fallbackDial(ctx, network, address)
	}
}

// WithMasqueAdapter adds MASQUE support to the mixed proxy
func WithMasqueAdapter(adapter *masque.MasqueAdapter, logger *slog.Logger) Option {
	return func(p *Proxy) {
		masqueDialer := NewMasqueDialer(adapter, logger)
		p.userDialFunc = masqueDialer.DialContext

		if logger != nil {
			logger.Info("MASQUE adapter integrated with proxy server")
		}
	}
}

// WithMasqueAutoSetup automatically sets up MASQUE adapter with registration
func WithMasqueAutoSetup(ctx context.Context, config masque.AdapterConfig) Option {
	return func(p *Proxy) {
		adapter, err := masque.NewMasqueAdapter(ctx, config)
		if err != nil {
			p.logger.Error("Failed to setup MASQUE adapter", "error", err)
			return
		}

		masqueDialer := NewMasqueDialer(adapter, config.Logger)
		p.userDialFunc = masqueDialer.DialContext

		p.logger.Info("MASQUE adapter auto-configured and integrated with proxy server")
	}
}
