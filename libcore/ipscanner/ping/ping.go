package ping

import (
	"context"
	"net/netip"

	"github.com/bepass-org/vwarp/ipscanner/statute"
)

type Ping struct {
	Options *statute.ScannerOptions
}

// IcmpPing performs an ICMP ping test on the given IP address.
func (p *Ping) IcmpPing(ctx context.Context, ip netip.Addr) (statute.IPInfo, error) {
	return p.calc(ctx, NewIcmpPing(ip, p.Options))
}

// WarpPing performs a WARP handshake test on the given IP address.
func (p *Ping) WarpPing(ctx context.Context, ip netip.Addr) (statute.IPInfo, error) {
	return p.calc(ctx, NewWarpPing(ip, p.Options))
}

// TcpPing performs a TCP connection test on the given IP address.
func (p *Ping) TcpPing(ctx context.Context, ip netip.Addr) (statute.IPInfo, error) {
	return p.calc(ctx,
		NewTcpPing(ip, p.Options.Hostname, p.Options.Port, p.Options),
	)
}

func (p *Ping) calc(ctx context.Context, tp statute.IPing) (statute.IPInfo, error) {
	pr := tp.PingContext(ctx)
	err := pr.Error()
	if err != nil {
		return statute.IPInfo{}, err
	}
	return pr.Result(), nil
}
