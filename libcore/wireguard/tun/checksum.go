package tun

import "encoding/binary"

// TODO: Explore SIMD and/or other assembly optimizations.
// TODO: Test native endian loads. See RFC 1071 section 2 part B.
func checksumNoFold(b []byte, initial uint64) uint64 {
	ac := initial

	for len(b) >= 128 {
		ac += uint64(binary.BigEndian.Uint32(b[:4]))
		ac += uint64(binary.BigEndian.Uint32(b[4:8]))
		ac += uint64(binary.BigEndian.Uint32(b[8:12]))
		ac += uint64(binary.BigEndian.Uint32(b[12:16]))
		ac += uint64(binary.BigEndian.Uint32(b[16:20]))
		ac += uint64(binary.BigEndian.Uint32(b[20:24]))
		ac += uint64(binary.BigEndian.Uint32(b[24:28]))
		ac += uint64(binary.BigEndian.Uint32(b[28:32]))
		ac += uint64(binary.BigEndian.Uint32(b[32:36]))
		ac += uint64(binary.BigEndian.Uint32(b[36:40]))
		ac += uint64(binary.BigEndian.Uint32(b[40:44]))
		ac += uint64(binary.BigEndian.Uint32(b[44:48]))
		ac += uint64(binary.BigEndian.Uint32(b[48:52]))
		ac += uint64(binary.BigEndian.Uint32(b[52:56]))
		ac += uint64(binary.BigEndian.Uint32(b[56:60]))
		ac += uint64(binary.BigEndian.Uint32(b[60:64]))
		ac += uint64(binary.BigEndian.Uint32(b[64:68]))
		ac += uint64(binary.BigEndian.Uint32(b[68:72]))
		ac += uint64(binary.BigEndian.Uint32(b[72:76]))
		ac += uint64(binary.BigEndian.Uint32(b[76:80]))
		ac += uint64(binary.BigEndian.Uint32(b[80:84]))
		ac += uint64(binary.BigEndian.Uint32(b[84:88]))
		ac += uint64(binary.BigEndian.Uint32(b[88:92]))
		ac += uint64(binary.BigEndian.Uint32(b[92:96]))
		ac += uint64(binary.BigEndian.Uint32(b[96:100]))
		ac += uint64(binary.BigEndian.Uint32(b[100:104]))
		ac += uint64(binary.BigEndian.Uint32(b[104:108]))
		ac += uint64(binary.BigEndian.Uint32(b[108:112]))
		ac += uint64(binary.BigEndian.Uint32(b[112:116]))
		ac += uint64(binary.BigEndian.Uint32(b[116:120]))
		ac += uint64(binary.BigEndian.Uint32(b[120:124]))
		ac += uint64(binary.BigEndian.Uint32(b[124:128]))
		b = b[128:]
	}
	if len(b) >= 64 {
		ac += uint64(binary.BigEndian.Uint32(b[:4]))
		ac += uint64(binary.BigEndian.Uint32(b[4:8]))
		ac += uint64(binary.BigEndian.Uint32(b[8:12]))
		ac += uint64(binary.BigEndian.Uint32(b[12:16]))
		ac += uint64(binary.BigEndian.Uint32(b[16:20]))
		ac += uint64(binary.BigEndian.Uint32(b[20:24]))
		ac += uint64(binary.BigEndian.Uint32(b[24:28]))
		ac += uint64(binary.BigEndian.Uint32(b[28:32]))
		ac += uint64(binary.BigEndian.Uint32(b[32:36]))
		ac += uint64(binary.BigEndian.Uint32(b[36:40]))
		ac += uint64(binary.BigEndian.Uint32(b[40:44]))
		ac += uint64(binary.BigEndian.Uint32(b[44:48]))
		ac += uint64(binary.BigEndian.Uint32(b[48:52]))
		ac += uint64(binary.BigEndian.Uint32(b[52:56]))
		ac += uint64(binary.BigEndian.Uint32(b[56:60]))
		ac += uint64(binary.BigEndian.Uint32(b[60:64]))
		b = b[64:]
	}
	if len(b) >= 32 {
		ac += uint64(binary.BigEndian.Uint32(b[:4]))
		ac += uint64(binary.BigEndian.Uint32(b[4:8]))
		ac += uint64(binary.BigEndian.Uint32(b[8:12]))
		ac += uint64(binary.BigEndian.Uint32(b[12:16]))
		ac += uint64(binary.BigEndian.Uint32(b[16:20]))
		ac += uint64(binary.BigEndian.Uint32(b[20:24]))
		ac += uint64(binary.BigEndian.Uint32(b[24:28]))
		ac += uint64(binary.BigEndian.Uint32(b[28:32]))
		b = b[32:]
	}
	if len(b) >= 16 {
		ac += uint64(binary.BigEndian.Uint32(b[:4]))
		ac += uint64(binary.BigEndian.Uint32(b[4:8]))
		ac += uint64(binary.BigEndian.Uint32(b[8:12]))
		ac += uint64(binary.BigEndian.Uint32(b[12:16]))
		b = b[16:]
	}
	if len(b) >= 8 {
		ac += uint64(binary.BigEndian.Uint32(b[:4]))
		ac += uint64(binary.BigEndian.Uint32(b[4:8]))
		b = b[8:]
	}
	if len(b) >= 4 {
		ac += uint64(binary.BigEndian.Uint32(b))
		b = b[4:]
	}
	if len(b) >= 2 {
		ac += uint64(binary.BigEndian.Uint16(b))
		b = b[2:]
	}
	if len(b) == 1 {
		ac += uint64(b[0]) << 8
	}

	return ac
}

func checksum(b []byte, initial uint64) uint16 {
	ac := checksumNoFold(b, initial)
	ac = (ac >> 16) + (ac & 0xffff)
	ac = (ac >> 16) + (ac & 0xffff)
	ac = (ac >> 16) + (ac & 0xffff)
	ac = (ac >> 16) + (ac & 0xffff)
	return uint16(ac)
}

func pseudoHeaderChecksumNoFold(protocol uint8, srcAddr, dstAddr []byte, totalLen uint16) uint64 {
	sum := checksumNoFold(srcAddr, 0)
	sum = checksumNoFold(dstAddr, sum)
	sum = checksumNoFold([]byte{0, protocol}, sum)
	tmp := make([]byte, 2)
	binary.BigEndian.PutUint16(tmp, totalLen)
	return checksumNoFold(tmp, sum)
}
