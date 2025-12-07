package masque

// DefaultMasqueV4CIDRs returns the default IPv4 CIDR ranges for MASQUE endpoints
func DefaultMasqueV4CIDRs() []string {
	return []string{
		"162.159.192.0/24",
		"162.159.193.0/24",
		"162.159.195.0/24",
		"162.159.196.0/24",
		"162.159.198.0/24",
	}
}

// DefaultMasqueV6CIDRs returns the default IPv6 CIDR ranges for MASQUE endpoints
func DefaultMasqueV6CIDRs() []string {
	return []string{
		"2606:4700:d0::/48",
		"2606:4700:d1::/48",
	}
}

// DefaultMasquePort returns the default port for MASQUE connections
func DefaultMasquePort() uint16 {
	return 443
}
