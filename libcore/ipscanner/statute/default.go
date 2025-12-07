package statute

import (
	"net/netip"
)

func DefaultCFRanges() []netip.Prefix {
	return []netip.Prefix{
		netip.MustParsePrefix("103.21.244.0/22"),
		netip.MustParsePrefix("103.22.200.0/22"),
		netip.MustParsePrefix("103.31.4.0/22"),
		netip.MustParsePrefix("104.16.0.0/12"),
		netip.MustParsePrefix("108.162.192.0/18"),
		netip.MustParsePrefix("131.0.72.0/22"),
		netip.MustParsePrefix("141.101.64.0/18"),
		netip.MustParsePrefix("162.158.0.0/15"),
		netip.MustParsePrefix("172.64.0.0/13"),
		netip.MustParsePrefix("173.245.48.0/20"),
		netip.MustParsePrefix("188.114.96.0/20"),
		netip.MustParsePrefix("190.93.240.0/20"),
		netip.MustParsePrefix("197.234.240.0/22"),
		netip.MustParsePrefix("198.41.128.0/17"),
		netip.MustParsePrefix("2400:cb00::/32"),
		netip.MustParsePrefix("2405:8100::/32"),
		netip.MustParsePrefix("2405:b500::/32"),
		netip.MustParsePrefix("2606:4700::/32"),
		netip.MustParsePrefix("2803:f800::/32"),
		netip.MustParsePrefix("2c0f:f248::/32"),
		netip.MustParsePrefix("2a06:98c0::/29"),
	}
}
