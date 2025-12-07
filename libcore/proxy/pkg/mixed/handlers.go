package mixed

import (
	"context"
	"log/slog"
	"net"

	"github.com/bepass-org/vwarp/proxy/pkg/statute"
)

func WithBindAddress(binAddress string) Option {
	return func(p *Proxy) {
		p.bind = binAddress
		p.socks5Proxy.Bind = binAddress
		p.socks4Proxy.Bind = binAddress
		p.httpProxy.Bind = binAddress
	}
}

func WithListener(ln net.Listener) Option {
	return func(p *Proxy) {
		p.listener = ln
		p.socks5Proxy.Listener = ln
		p.socks4Proxy.Listener = ln
		p.httpProxy.Listener = ln
	}
}

func WithLogger(logger *slog.Logger) Option {
	return func(p *Proxy) {
		p.logger = logger
		p.socks5Proxy.Logger = logger
		p.socks4Proxy.Logger = logger
		p.httpProxy.Logger = logger
	}
}

func WithUserHandler(handler userHandler) Option {
	return func(p *Proxy) {
		p.userHandler = handler
		p.socks5Proxy.UserConnectHandle = statute.UserConnectHandler(handler)
		p.socks5Proxy.UserAssociateHandle = statute.UserAssociateHandler(handler)
		p.socks4Proxy.UserConnectHandle = statute.UserConnectHandler(handler)
		p.httpProxy.UserConnectHandle = statute.UserConnectHandler(handler)
	}
}

func WithUserTCPHandler(handler userHandler) Option {
	return func(p *Proxy) {
		p.userTCPHandler = handler
		p.socks5Proxy.UserConnectHandle = statute.UserConnectHandler(handler)
		p.socks4Proxy.UserConnectHandle = statute.UserConnectHandler(handler)
		p.httpProxy.UserConnectHandle = statute.UserConnectHandler(handler)
	}
}

func WithUserUDPHandler(handler userHandler) Option {
	return func(p *Proxy) {
		p.userUDPHandler = handler
		p.socks5Proxy.UserAssociateHandle = statute.UserAssociateHandler(handler)
	}
}

func WithUserDialFunc(proxyDial statute.ProxyDialFunc) Option {
	return func(p *Proxy) {
		p.userDialFunc = proxyDial
		p.socks5Proxy.ProxyDial = proxyDial
		p.socks4Proxy.ProxyDial = proxyDial
		p.httpProxy.ProxyDial = proxyDial
	}
}

func WithUserListenPacketFunc(proxyListenPacket statute.ProxyListenPacket) Option {
	return func(p *Proxy) {
		p.socks5Proxy.ProxyListenPacket = proxyListenPacket
	}
}

func WithUserForwardAddressFunc(packetForwardAddress statute.PacketForwardAddress) Option {
	return func(p *Proxy) {
		p.socks5Proxy.PacketForwardAddress = packetForwardAddress
	}
}

func WithContext(ctx context.Context) Option {
	return func(p *Proxy) {
		p.ctx = ctx
		p.socks5Proxy.Context = ctx
		p.socks4Proxy.Context = ctx
		p.httpProxy.Context = ctx
	}
}

func WithBytesPool(bytesPool statute.BytesPool) Option {
	return func(p *Proxy) {
		p.socks5Proxy.BytesPool = bytesPool
		p.socks4Proxy.BytesPool = bytesPool
		p.httpProxy.BytesPool = bytesPool
	}
}
