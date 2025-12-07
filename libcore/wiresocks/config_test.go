package wiresocks

import (
	"net/netip"
	"testing"

	qt "github.com/frankban/quicktest"
	"github.com/go-ini/ini"
	"github.com/google/go-cmp/cmp/cmpopts"
)

const testConfig = `
[Interface]
PrivateKey = aK8FWhiV1CtKFbKUPssL13P+Tv+c5owmYcU5PCP6yFw=
DNS = 8.8.8.8
Address = 172.16.0.2/24
Address = 2606:4700:110:8cc0:1ad3:9155:6742:ea8d/128
MTU = 1500
[Peer]
PublicKey = bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=
AllowedIPs = 0.0.0.0/0
AllowedIPs = ::/0
Endpoint = engage.cloudflareclient.com:2408
PersistentKeepalive = 3
Trick = true
Reserved = 1,2,3
`
const (
	privateKeyBase64   = "68af055a1895d42b4a15b2943ecb0bd773fe4eff9ce68c2661c5393c23fac85c"
	publicKeyBase64    = "6e65ce0be17517110c17d77288ad87e7fd5252dcc7d09b95a39d61db03df832a"
	presharedKeyBase64 = "0000000000000000000000000000000000000000000000000000000000000000"
)

func TestParseInterface(t *testing.T) {
	opts := ini.LoadOptions{
		Insensitive:            true,
		AllowShadows:           true,
		AllowNonUniqueSections: true,
	}

	cfg, err := ini.LoadSources(opts, []byte(testConfig))
	qt.Assert(t, err, qt.IsNil)

	device, err := ParseInterface(cfg)
	qt.Assert(t, err, qt.IsNil)

	want := InterfaceConfig{
		PrivateKey: privateKeyBase64,
		Addresses: []netip.Addr{
			netip.MustParseAddr("172.16.0.2"),
			netip.MustParseAddr("2606:4700:110:8cc0:1ad3:9155:6742:ea8d"),
		},
		DNS: []netip.Addr{netip.MustParseAddr("8.8.8.8")},
		MTU: 1500,
	}
	qt.Assert(t, device, qt.CmpEquals(cmpopts.EquateComparable(netip.Addr{})), want)
	t.Logf("%+v", device)
}

func TestParsePeers(t *testing.T) {
	opts := ini.LoadOptions{
		Insensitive:            true,
		AllowShadows:           true,
		AllowNonUniqueSections: true,
	}

	cfg, err := ini.LoadSources(opts, []byte(testConfig))
	qt.Assert(t, err, qt.IsNil)

	peers, err := ParsePeers(cfg)
	qt.Assert(t, err, qt.IsNil)

	want := []PeerConfig{{
		PublicKey:    publicKeyBase64,
		PreSharedKey: presharedKeyBase64,
		Endpoint:     "engage.cloudflareclient.com:2408",
		KeepAlive:    3,
		AllowedIPs: []netip.Prefix{
			netip.MustParsePrefix("0.0.0.0/0"),
			netip.MustParsePrefix("::/0"),
		},
		Trick:    true,
		Reserved: [3]byte{1, 2, 3},
	}}
	qt.Assert(t, peers, qt.CmpEquals(cmpopts.EquateComparable(netip.Prefix{})), want)
	t.Logf("%+v", peers)
}
