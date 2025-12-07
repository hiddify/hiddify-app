module github.com/bepass-org/vwarp

go 1.24.1

toolchain go1.24.6

// +build android
replace github.com/eycorsican/go-tun2socks => github.com/trojan-gfw/go-tun2socks v1.16.3-0.20210702214000-083d49176e05

// Fix Linux netlink compatibility with newer version
replace github.com/tailscale/netlink => github.com/tailscale/netlink v1.1.1-0.20240822203006-4d49adab4de7

require (
	github.com/Diniboy1123/connect-ip-go v0.0.0-20251011145655-7be32d5976d9
	github.com/Diniboy1123/usque v1.4.2
	github.com/Psiphon-Labs/psiphon-tunnel-core v1.0.11-0.20251029164303-aa4d266ae982
	github.com/adrg/xdg v0.5.3
	github.com/avast/retry-go v3.0.0+incompatible
	github.com/carlmjohnson/versioninfo v0.22.5
	github.com/eycorsican/go-tun2socks v1.16.11
	github.com/fatih/color v1.18.0
	github.com/flynn/noise v1.1.0
	github.com/frankban/quicktest v1.14.6
	github.com/go-ini/ini v1.67.0
	github.com/google/go-cmp v0.7.0
	github.com/noql-net/certpool v0.0.0-20250417123926-688b52c002ee
	github.com/peterbourgon/ff/v4 v4.0.0-alpha.4
	github.com/quic-go/quic-go v0.55.0
	github.com/refraction-networking/utls v1.7.3
	github.com/rodaine/table v1.3.0
	github.com/sagernet/gvisor v0.0.0-20250811-sing-box-mod.1
	github.com/sagernet/sing v0.7.13
	github.com/songgao/water v0.0.0-20200317203138-2b4b6d7c09d8
	github.com/yosida95/uritemplate/v3 v3.0.2
	golang.org/x/crypto v0.43.0
	golang.org/x/net v0.46.0
	golang.org/x/sys v0.37.0
)

require (
	filippo.io/bigmod v0.0.1 // indirect
	filippo.io/edwards25519 v1.1.0 // indirect
	filippo.io/keygen v0.0.0-20230306160926-5201437acf8e // indirect
	github.com/AndreasBriese/bbloom v0.0.0-20190825152654-46b345b51c96 // indirect
	github.com/Jigsaw-Code/outline-sdk v0.0.16 // indirect
	github.com/Psiphon-Labs/bolt v0.0.0-20200624191537-23cedaef7ad7 // indirect
	github.com/Psiphon-Labs/consistent v0.0.0-20240322131436-20aaa4e05737 // indirect
	github.com/Psiphon-Labs/goptlib v0.0.0-20200406165125-c0e32a7a3464 // indirect
	github.com/Psiphon-Labs/psiphon-tls v0.0.0-20250318183125-2a2fae2db378 // indirect
	github.com/Psiphon-Labs/quic-go v0.0.0-20250527153145-79fe45fb83b1 // indirect
	github.com/Psiphon-Labs/utls v0.0.0-20250623193530-396869e9cd87 // indirect
	github.com/alexbrainman/sspi v0.0.0-20231016080023-1a75b4708caa // indirect
	github.com/andybalholm/brotli v1.1.1 // indirect
	github.com/armon/go-proxyproto v0.0.0-20180202201750-5b7edb60ff5f // indirect
	github.com/bifurcation/mint v0.0.0-20180306135233-198357931e61 // indirect
	github.com/bits-and-blooms/bitset v1.10.0 // indirect
	github.com/bits-and-blooms/bloom/v3 v3.6.0 // indirect
	github.com/cespare/xxhash v1.1.0 // indirect
	github.com/cheekybits/genny v0.0.0-20170328200008-9127e812e1e9 // indirect
	github.com/cloudflare/circl v1.6.1 // indirect
	github.com/cognusion/go-cache-lru v0.0.0-20170419142635-f73e2280ecea // indirect
	github.com/coreos/go-iptables v0.7.0 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/dblohm7/wingoes v0.0.0-20230929194252-e994401fc077 // indirect
	github.com/dchest/siphash v1.2.3 // indirect
	github.com/dgraph-io/badger v1.5.4-0.20180815194500-3a87f6d9c273 // indirect
	github.com/dgryski/go-farm v0.0.0-20240924180020-3414d57e47da // indirect
	github.com/djherbis/buffer v1.2.0 // indirect
	github.com/djherbis/nio v2.0.3+incompatible // indirect
	github.com/dunglas/httpsfv v1.1.0 // indirect
	github.com/fxamacker/cbor/v2 v2.5.0 // indirect
	github.com/go-ole/go-ole v1.3.0 // indirect
	github.com/golang/groupcache v0.0.0-20210331224755-41bb18bfe9da // indirect
	github.com/golang/protobuf v1.5.4 // indirect
	github.com/google/btree v1.1.3 // indirect
	github.com/google/nftables v0.1.1-0.20230115205135-9aa6fdf5a28c // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/grafov/m3u8 v0.0.0-20171211212457-6ab8f28ed427 // indirect
	github.com/hashicorp/golang-lru v1.0.2 // indirect
	github.com/josharian/native v1.1.1-0.20230202152459-5c7d0dd6ab86 // indirect
	github.com/jsimonetti/rtnetlink v1.3.5 // indirect
	github.com/klauspost/compress v1.18.0 // indirect
	github.com/kr/pretty v0.3.1 // indirect
	github.com/kr/text v0.2.0 // indirect
	github.com/libp2p/go-reuseport v0.4.0 // indirect
	github.com/marusama/semaphore v0.0.0-20171214154724-565ffd8e868a // indirect
	github.com/mattn/go-colorable v0.1.13 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	github.com/mdlayher/netlink v1.7.2 // indirect
	github.com/mdlayher/socket v0.5.0 // indirect
	github.com/miekg/dns v1.1.56 // indirect
	github.com/mroth/weightedrand v1.0.0 // indirect
	github.com/onsi/gomega v1.27.10 // indirect
	github.com/pelletier/go-toml v1.9.5 // indirect
	github.com/pion/datachannel v1.5.5 // indirect
	github.com/pion/dtls/v2 v2.2.7 // indirect
	github.com/pion/ice/v2 v2.3.24 // indirect
	github.com/pion/interceptor v0.1.25 // indirect
	github.com/pion/logging v0.2.2 // indirect
	github.com/pion/mdns v0.0.12 // indirect
	github.com/pion/randutil v0.1.0 // indirect
	github.com/pion/rtcp v1.2.12 // indirect
	github.com/pion/rtp v1.8.5 // indirect
	github.com/pion/sctp v1.8.16 // indirect
	github.com/pion/sdp/v3 v3.0.9 // indirect
	github.com/pion/srtp/v2 v2.0.18 // indirect
	github.com/pion/stun v0.6.1 // indirect
	github.com/pion/transport/v2 v2.2.4 // indirect
	github.com/pion/turn/v2 v2.1.3 // indirect
	github.com/pion/webrtc/v3 v3.2.40 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	github.com/quic-go/qpack v0.5.1 // indirect
	github.com/refraction-networking/conjure v0.7.11-0.20240130155008-c8df96195ab2 // indirect
	github.com/refraction-networking/ed25519 v0.1.2 // indirect
	github.com/refraction-networking/gotapdance v1.7.10 // indirect
	github.com/refraction-networking/obfs4 v0.1.2 // indirect
	github.com/rogpeppe/go-internal v1.13.1 // indirect
	github.com/sergeyfrolov/bsbuffer v0.0.0-20180903213811-94e85abb8507 // indirect
	github.com/shadowsocks/go-shadowsocks2 v0.1.5 // indirect
	github.com/sirupsen/logrus v1.9.3 // indirect
	github.com/stretchr/testify v1.11.0 // indirect
	github.com/syndtr/gocapability v0.0.0-20200815063812-42c35b437635 // indirect
	github.com/tailscale/goupnp v1.0.1-0.20210804011211-c64d0f06ea05 // indirect
	github.com/tailscale/netlink v1.1.1-0.20240822203006-4d49adab4de7 // indirect
	github.com/v2pro/plz v0.0.0-20221028024117-e5f9aec5b631 // indirect
	github.com/vishvananda/netns v0.0.5 // indirect
	github.com/wader/filtertransport v0.0.0-20200316221534-bdd9e61eee78 // indirect
	github.com/wlynxg/anet v0.0.5 // indirect
	github.com/x448/float16 v0.8.4 // indirect
	gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/goptlib v1.5.0 // indirect
	go4.org/mem v0.0.0-20220726221520-4f986261bf13 // indirect
	go4.org/netipx v0.0.0-20230824141953-6213f710f925 // indirect
	golang.org/x/exp v0.0.0-20240506185415-9bf2ced13842 // indirect
	golang.org/x/mod v0.29.0 // indirect
	golang.org/x/sync v0.17.0 // indirect
	golang.org/x/text v0.30.0 // indirect
	golang.org/x/time v0.14.0 // indirect
	golang.org/x/tools v0.38.0 // indirect
	golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2 // indirect
	golang.zx2c4.com/wireguard v0.0.0-20250521234502-f333402bd9cb // indirect
	golang.zx2c4.com/wireguard/windows v0.5.3 // indirect
	google.golang.org/protobuf v1.36.8 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
	gvisor.dev/gvisor v0.0.0-20251011013117-af7a19336e55 // indirect
	tailscale.com v1.58.2 // indirect
)
