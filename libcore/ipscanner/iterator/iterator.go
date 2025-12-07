package iterator

import (
	"crypto/rand"
	"errors"
	"github.com/bepass-org/vwarp/ipscanner/statute"
	"math/big"
	"net"
	"net/netip"
	"sync"
)

// LCG represents a linear congruential generator with full period.
type LCG struct {
	modulus    *big.Int
	multiplier *big.Int
	increment  *big.Int
	current    *big.Int
}

// NewLCG creates a new LCG instance with a given size.
func NewLCG(size *big.Int) *LCG {
	modulus := new(big.Int).Set(size)

	// Generate random multiplier (a) and increment (c) that satisfy Hull-Dobell Theorem
	var multiplier, increment *big.Int
	for {
		var err error
		multiplier, err = rand.Int(rand.Reader, modulus)
		if err != nil {
			continue
		}
		increment, err = rand.Int(rand.Reader, modulus)
		if err != nil {
			continue
		}

		// Check Hull-Dobell Theorem conditions
		if checkHullDobell(modulus, multiplier, increment) {
			break
		}
	}

	return &LCG{
		modulus:    modulus,
		multiplier: multiplier,
		increment:  increment,
		current:    big.NewInt(0),
	}
}

// checkHullDobell checks if the given parameters satisfy the Hull-Dobell Theorem.
func checkHullDobell(modulus, multiplier, increment *big.Int) bool {
	// c and m are relatively prime
	gcd := new(big.Int).GCD(nil, nil, increment, modulus)
	if gcd.Cmp(big.NewInt(1)) != 0 {
		return false
	}

	// a - 1 is divisible by all prime factors of m
	aMinusOne := new(big.Int).Sub(multiplier, big.NewInt(1))

	// a - 1 is divisible by 4 if m is divisible by 4
	if new(big.Int).And(modulus, big.NewInt(3)).Cmp(big.NewInt(0)) == 0 {
		if new(big.Int).And(aMinusOne, big.NewInt(3)).Cmp(big.NewInt(0)) != 0 {
			return false
		}
	}

	return true
}

// Next generates the next number in the sequence.
func (lcg *LCG) Next() *big.Int {
	if lcg.current.Cmp(lcg.modulus) == 0 {
		return nil // Sequence complete
	}

	next := new(big.Int)
	next.Mul(lcg.multiplier, lcg.current)
	next.Add(next, lcg.increment)
	next.Mod(next, lcg.modulus)

	lcg.current.Set(next)
	return next
}

type ipRange struct {
	prefix netip.Prefix
	lcg    *LCG
	start  netip.Addr
	stop   netip.Addr
	size   *big.Int
	index  *big.Int
}

func newIPRange(cidr netip.Prefix) (ipRange, error) {
	startIP := cidr.Addr()
	stopIP := lastIP(cidr)
	size := ipRangeSize(cidr)
	return ipRange{
		prefix: cidr,
		start:  startIP,
		stop:   stopIP,
		size:   size,
		index:  big.NewInt(0),
		lcg:    NewLCG(size),
	}, nil
}

func lastIP(prefix netip.Prefix) netip.Addr {
	// Calculate the number of bits to fill for the last address based on the address family
	fillBits := 128 - prefix.Bits()
	if prefix.Addr().Is4() {
		fillBits = 32 - prefix.Bits()
	}

	// Calculate the numerical representation of the last address by setting the remaining bits to 1
	var lastAddrInt big.Int
	lastAddrInt.SetBytes(prefix.Addr().AsSlice())
	for i := 0; i < fillBits; i++ {
		lastAddrInt.SetBit(&lastAddrInt, i, 1)
	}

	// Convert the big.Int back to netip.Addr
	lastAddrBytes := lastAddrInt.Bytes()
	var lastAddr netip.Addr
	if prefix.Addr().Is4() {
		// Ensure the slice is the right length for IPv4
		if len(lastAddrBytes) < net.IPv4len {
			leadingZeros := make([]byte, net.IPv4len-len(lastAddrBytes))
			lastAddrBytes = append(leadingZeros, lastAddrBytes...)
		}
		lastAddr, _ = netip.AddrFromSlice(lastAddrBytes[len(lastAddrBytes)-net.IPv4len:])
	} else {
		// Ensure the slice is the right length for IPv6
		if len(lastAddrBytes) < net.IPv6len {
			leadingZeros := make([]byte, net.IPv6len-len(lastAddrBytes))
			lastAddrBytes = append(leadingZeros, lastAddrBytes...)
		}
		lastAddr, _ = netip.AddrFromSlice(lastAddrBytes)
	}

	return lastAddr
}

func addIP(ip netip.Addr, num *big.Int) netip.Addr {
	addrAs16 := ip.As16()
	ipInt := new(big.Int).SetBytes(addrAs16[:])
	ipInt.Add(ipInt, num)
	addr, _ := netip.AddrFromSlice(ipInt.FillBytes(make([]byte, 16)))
	return addr.Unmap()
}

func ipRangeSize(prefix netip.Prefix) *big.Int {
	// The number of bits in the address depends on whether it's IPv4 or IPv6.
	totalBits := 128 // Assume IPv6 by default
	if prefix.Addr().Is4() {
		totalBits = 32 // Adjust for IPv4
	}

	// Calculate the size of the range
	bits := prefix.Bits() // This is the prefix length
	size := big.NewInt(1)
	size.Lsh(size, uint(totalBits-bits)) // Left shift to calculate the range size

	return size
}

type IpGenerator struct {
	ipRanges []ipRange
	opts     *statute.ScannerOptions
	mu       sync.Mutex
}

// generateIPsFromRange selects a specified number of IPs distributed across a given range.
// It divides the range into `count` segments and picks one random IP from each segment.
// This modified version ensures that for IPv4, addresses ending in .0 or .255 are not selected.
func (g *IpGenerator) generateIPsFromRange(r ipRange, count int) ([]netip.Addr, error) {
	var ips []netip.Addr

	// Cannot generate more IPs than available in the range.
	if r.size.Cmp(big.NewInt(int64(count))) < 0 {
		count = int(r.size.Int64())
	}
	if count == 0 {
		return ips, nil
	}

	// Divide the range into `count` segments.
	segmentSize := new(big.Int).Div(r.size, big.NewInt(int64(count)))

	for i := 0; i < count; i++ {
		segStart := new(big.Int).Mul(big.NewInt(int64(i)), segmentSize)

		segEnd := new(big.Int).Add(segStart, segmentSize)
		if i == count-1 {
			// Last segment takes the remainder to cover the whole range.
			segEnd.Set(r.size)
		}

		// Calculate the actual size of this segment.
		currentSegmentSize := new(big.Int).Sub(segEnd, segStart)
		if currentSegmentSize.Cmp(big.NewInt(0)) <= 0 {
			continue
		}

		var ip netip.Addr
		var foundValidIP bool
		// Set a limit for retries to avoid infinite loops in segments
		// that might only contain invalid endpoint IPs (.0 or .255).
		const maxRetries = 10

		for attempt := 0; attempt < maxRetries; attempt++ {
			// Get a random offset within the segment.
			offset, err := rand.Int(rand.Reader, currentSegmentSize)
			if err != nil {
				return nil, err
			}

			// Add segment start to the offset to get the final offset from the beginning of the range.
			finalOffset := new(big.Int).Add(segStart, offset)

			// Add the offset to the range's start IP.
			candidateIP := addIP(r.start, finalOffset)

			if !candidateIP.IsValid() {
				continue // Safeguard against invalid IPs.
			}

			// For IPv4, check if the address is a network or broadcast address.
			if candidateIP.Is4() {
				addrBytes := candidateIP.As4()
				lastOctet := addrBytes[3]
				// A valid endpoint should not end in 0 or 255.
				if lastOctet != 0 && lastOctet != 255 {
					ip = candidateIP
					foundValidIP = true
					break // A valid endpoint IP was found.
				}
				// If invalid, the loop continues to try another random IP.
			} else {
				// For IPv6, the .0/.255 rule does not apply.
				ip = candidateIP
				foundValidIP = true
				break
			}
		}

		// Only add the IP if a valid one was found within the retry limit.
		if foundValidIP {
			ips = append(ips, ip)
		}
	}

	return ips, nil
}

// Generate creates the initial list of candidate IPs by splitting ranges and sampling.
func (g *IpGenerator) Generate() ([]netip.Addr, error) {
	g.mu.Lock()
	defer g.mu.Unlock()

	var results []netip.Addr
	ipsPerSubnet := g.opts.BucketSize

	for _, r := range g.ipRanges {
		originalPrefix := r.prefix

		if originalPrefix.Addr().Is4() {
			subnetBits := 24 // Target subnet size for IPv4
			if originalPrefix.Bits() >= subnetBits {
				// The range is a /24 or smaller, so we scan it directly.
				ips, err := g.generateIPsFromRange(r, ipsPerSubnet)
				if err != nil {
					continue
				}
				results = append(results, ips...)
			} else {
				// The range is larger than a /24. Iterate through all /24 subnets within it.
				subnetSize := ipRangeSize(netip.PrefixFrom(originalPrefix.Addr(), subnetBits))
				current := originalPrefix.Addr()
				for originalPrefix.Contains(current) {
					subnet := netip.PrefixFrom(current, subnetBits)
					subnetRange := ipRange{start: subnet.Addr(), size: ipRangeSize(subnet)}
					ips, err := g.generateIPsFromRange(subnetRange, ipsPerSubnet)
					if err != nil {
						break
					}
					results = append(results, ips...)

					// Move to the next /24 subnet
					nextAddr := addIP(current, subnetSize)
					if !nextAddr.IsValid() || nextAddr.Compare(current) <= 0 { // Overflow check
						break
					}
					current = nextAddr
				}
			}
		} else { // IPv6
			subnetBits := 120              // Use /120 as the equivalent of IPv4's /24 (256 addresses)
			const sampleSubnetsCount = 100 // Number of random subnets to sample from a large range

			if originalPrefix.Bits() >= subnetBits {
				// Range is a /120 or smaller, scan it directly.
				ips, err := g.generateIPsFromRange(r, ipsPerSubnet)
				if err != nil {
					continue
				}
				results = append(results, ips...)
			} else {
				// The range is larger than a /120. Iterating all is infeasible.
				// Instead, we randomly sample a fixed number of /120 subnets.
				randomBits := subnetBits - originalPrefix.Bits()
				numSubnets := new(big.Int).Lsh(big.NewInt(1), uint(randomBits))

				for i := 0; i < sampleSubnetsCount; i++ {
					// Get a random index for a subnet within the larger range.
					randomIndex, err := rand.Int(rand.Reader, numSubnets)
					if err != nil {
						continue
					}

					// Calculate the offset to find the start of the random subnet.
					hostBits := 128 - subnetBits // 8 bits for /120
					subnetOffset := new(big.Int).Lsh(randomIndex, uint(hostBits))
					subnetStartAddr := addIP(originalPrefix.Addr(), subnetOffset)

					// Generate IPs from this randomly sampled subnet.
					subnetPrefix := netip.PrefixFrom(subnetStartAddr, subnetBits)
					subnetRange := ipRange{start: subnetPrefix.Addr(), size: ipRangeSize(subnetPrefix)}
					ips, err := g.generateIPsFromRange(subnetRange, ipsPerSubnet)
					if err != nil {
						continue
					}
					results = append(results, ips...)
				}
			}
		}
	}

	if len(results) == 0 {
		return nil, errors.New("no IP ranges configured or no IPs generated")
	}
	return results, nil
}

// shuffleSubnetsIpRange shuffles a slice of ipRange using crypto/rand
func shuffleSubnetsIpRange(subnets []ipRange) error {
	for i := range subnets {
		jBig, err := rand.Int(rand.Reader, big.NewInt(int64(len(subnets))))
		if err != nil {
			return err
		}
		j := jBig.Int64()

		subnets[i], subnets[j] = subnets[j], subnets[i]
	}
	return nil
}

func NewIterator(opts *statute.ScannerOptions) *IpGenerator {
	g := &IpGenerator{
		ipRanges: make([]ipRange, 0),
		opts:     opts,
	}

	for _, cidr := range opts.CidrList {
		if !opts.UseIPv6 && cidr.Addr().Is6() {
			continue
		}
		if !opts.UseIPv4 && cidr.Addr().Is4() {
			continue
		}

		ipRange, err := newIPRange(cidr)
		if err != nil {
			opts.Logger.Warn("failed to create IP range from CIDR", "cidr", cidr.String(), "error", err)
			continue
		}
		g.ipRanges = append(g.ipRanges, ipRange)
	}

	if len(g.ipRanges) > 1 {
		err := shuffleSubnetsIpRange(g.ipRanges)
		if err != nil {
			// Log the error but don't fail; proceed with unshuffled ranges.
			opts.Logger.Error("failed to shuffle IP ranges", "error", err)
		}
	}

	return g
}
