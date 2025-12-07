package masque

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"net"
	"net/http"

	connectip "github.com/Diniboy1123/connect-ip-go"
	"github.com/bepass-org/vwarp/masque/noize"
	"github.com/quic-go/quic-go"
	"github.com/quic-go/quic-go/http3"
	"github.com/yosida95/uritemplate/v3"
)

// ConnectTunnelWithNoize connects to MASQUE server with optional noize obfuscation
// This is a modified version of usque's ConnectTunnel that supports UDP connection wrapping
func ConnectTunnelWithNoize(
	ctx context.Context,
	tlsConfig *tls.Config,
	quicConfig *quic.Config,
	connectUri string,
	endpoint *net.UDPAddr,
	noizeConfig *noize.NoizeConfig,
) (*net.UDPConn, *http3.Transport, *connectip.Conn, *http.Response, error) {

	// Create UDP connection
	var udpConn *net.UDPConn
	var err error
	if endpoint.IP.To4() == nil {
		udpConn, err = net.ListenUDP("udp", &net.UDPAddr{
			IP:   net.IPv6zero,
			Port: 0,
		})
	} else {
		udpConn, err = net.ListenUDP("udp", &net.UDPAddr{
			IP:   net.IPv4zero,
			Port: 0,
		})
	}
	if err != nil {
		return nil, nil, nil, nil, err
	}

	// Wrap UDP connection with noize if config is provided
	var quicConn net.PacketConn = udpConn
	if noizeConfig != nil {
		noizeConn := noize.WrapUDPConn(udpConn, noizeConfig)
		quicConn = noizeConn
	}

	// Dial QUIC connection
	conn, err := quic.Dial(
		ctx,
		quicConn,
		endpoint,
		tlsConfig,
		quicConfig,
	)
	if err != nil {
		return udpConn, nil, nil, nil, err
	}

	// Create HTTP/3 transport
	tr := &http3.Transport{
		EnableDatagrams: true,
		AdditionalSettings: map[uint64]uint64{
			// SETTINGS_H3_DATAGRAM_00 = 0x0000000000000276
			0x276: 1,
		},
		DisableCompression: true,
	}

	hconn := tr.NewClientConn(conn)

	additionalHeaders := http.Header{
		"User-Agent": []string{""},
	}

	template := uritemplate.MustNew(connectUri)
	ipConn, rsp, err := connectip.Dial(ctx, hconn, template, "cf-connect-ip", additionalHeaders, true)
	if err != nil {
		if err.Error() == "CRYPTO_ERROR 0x131 (remote): tls: access denied" {
			return udpConn, nil, nil, nil, errors.New("login failed! Please double-check if your tls key and cert is enrolled in the Cloudflare Access service")
		}
		return udpConn, nil, nil, nil, fmt.Errorf("failed to dial connect-ip: %v", err)
	}

	return udpConn, tr, ipConn, rsp, nil
}
