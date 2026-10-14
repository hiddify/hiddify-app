package tunnel

import (
	"context"
	"fmt"
	"net/netip"
	"syscall"

	"github.com/sagernet/sing-box/common/process"
	"github.com/sagernet/sing-box/experimental/libbox"
)

// FindConnectionOwner uses the same Darwin socket/process lookup as the desktop
// core. libbox delegates to the platform callback when a Network Extension is
// present, so it does not select this native searcher itself.
func FindConnectionOwner(ipProtocol int32, sourceAddress string, sourcePort int32) (*libbox.ConnectionOwner, error) {
	var network string
	switch ipProtocol {
	case syscall.IPPROTO_TCP:
		network = "tcp"
	case syscall.IPPROTO_UDP:
		network = "udp"
	default:
		return nil, fmt.Errorf("unsupported process lookup protocol: %d", ipProtocol)
	}
	source, err := netip.ParseAddr(sourceAddress)
	if err != nil {
		return nil, fmt.Errorf("invalid process lookup source address: %w", err)
	}
	if sourcePort <= 0 || sourcePort > 65535 {
		return nil, fmt.Errorf("invalid process lookup source port: %d", sourcePort)
	}
	searcher, err := process.NewSearcher(process.Config{})
	if err != nil {
		return nil, err
	}
	// Darwin identifies the socket by its local endpoint, including wildcard UDP
	// binds. A destination may still be a domain and is not needed by its searcher.
	owner, err := searcher.FindProcessInfo(context.Background(), network,
		netip.AddrPortFrom(source.Unmap(), uint16(sourcePort)), netip.AddrPort{})
	if err != nil {
		return nil, err
	}
	return &libbox.ConnectionOwner{
		ProcessPath: owner.ProcessPath,
		UserId:      owner.UserId,
		UserName:    owner.UserName,
	}, nil
}
