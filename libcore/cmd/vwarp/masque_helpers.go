package main

import (
	"fmt"
	"math/rand"
	"net/netip"

	"github.com/bepass-org/vwarp/masque"
)

// randomMasqueEndpoint returns a random MASQUE endpoint from Cloudflare's ranges
func randomMasqueEndpoint(v4, v6 bool) (netip.AddrPort, error) {
	var candidates []string

	if v4 {
		// Get IPv4 MASQUE CIDRs and select random IPs
		cidrs := masque.DefaultMasqueV4CIDRs()
		for _, cidr := range cidrs {
			prefix, err := netip.ParsePrefix(cidr)
			if err != nil {
				continue
			}
			// Get a few random IPs from each CIDR
			for i := 0; i < 5; i++ {
				addr := randomIPFromPrefix(prefix)
				if addr.IsValid() {
					candidates = append(candidates, fmt.Sprintf("%s:%d", addr, masque.DefaultMasquePort()))
				}
			}
		}
	}

	if v6 {
		// Get IPv6 MASQUE CIDRs and select random IPs
		cidrs := masque.DefaultMasqueV6CIDRs()
		for _, cidr := range cidrs {
			prefix, err := netip.ParsePrefix(cidr)
			if err != nil {
				continue
			}
			// Get a few random IPs from each CIDR
			for i := 0; i < 5; i++ {
				addr := randomIPFromPrefix(prefix)
				if addr.IsValid() {
					candidates = append(candidates, fmt.Sprintf("[%s]:%d", addr, masque.DefaultMasquePort()))
				}
			}
		}
	}

	if len(candidates) == 0 {
		return netip.AddrPort{}, fmt.Errorf("no MASQUE endpoints available")
	}

	// Pick a random candidate
	selected := candidates[rand.Intn(len(candidates))]
	return netip.ParseAddrPort(selected)
}

// randomIPFromPrefix generates a random IP address within the given prefix
func randomIPFromPrefix(prefix netip.Prefix) netip.Addr {
	addr := prefix.Addr()
	bits := prefix.Bits()

	if addr.Is4() {
		// IPv4
		ip := addr.As4()
		// Generate random bits for the host portion
		hostBits := 32 - bits
		if hostBits > 0 {
			// Generate random host bits
			randomHost := rand.Intn(1 << hostBits)
			// Apply the random bits to the IP
			ipInt := uint32(ip[0])<<24 | uint32(ip[1])<<16 | uint32(ip[2])<<8 | uint32(ip[3])
			// Clear host bits and apply random
			mask := ^uint32(0) << hostBits
			ipInt = (ipInt & mask) | uint32(randomHost)
			// Convert back to IP
			newIP := [4]byte{
				byte(ipInt >> 24),
				byte(ipInt >> 16),
				byte(ipInt >> 8),
				byte(ipInt),
			}
			return netip.AddrFrom4(newIP)
		}
		return addr
	} else {
		// IPv6 - simplified random generation
		ip := addr.As16()
		// For simplicity, just randomize the last 64 bits for typical /64 prefixes
		hostBits := 128 - bits
		if hostBits > 0 {
			// Randomize the last few bytes
			for i := 15; i >= 16-(hostBits/8) && i >= 0; i-- {
				ip[i] = byte(rand.Intn(256))
			}
		}
		return netip.AddrFrom16(ip)
	}
}
