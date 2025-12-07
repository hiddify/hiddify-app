/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package tun

import (
	"net/netip"
	"testing"

	"github.com/bepass-org/vwarp/wireguard/conn"
	"github.com/sagernet/gvisor/pkg/tcpip"
	"github.com/sagernet/gvisor/pkg/tcpip/header"
	"golang.org/x/sys/unix"
)

const (
	offset = virtioNetHdrLen
)

var (
	ip4PortA = netip.MustParseAddrPort("192.0.2.1:1")
	ip4PortB = netip.MustParseAddrPort("192.0.2.2:1")
	ip4PortC = netip.MustParseAddrPort("192.0.2.3:1")
	ip6PortA = netip.MustParseAddrPort("[2001:db8::1]:1")
	ip6PortB = netip.MustParseAddrPort("[2001:db8::2]:1")
	ip6PortC = netip.MustParseAddrPort("[2001:db8::3]:1")
)

func udp4PacketMutateIPFields(srcIPPort, dstIPPort netip.AddrPort, payloadLen int, ipFn func(*header.IPv4Fields)) []byte {
	totalLen := 28 + payloadLen
	b := make([]byte, offset+int(totalLen), 65535)
	ipv4H := header.IPv4(b[offset:])
	srcAs4 := srcIPPort.Addr().As4()
	dstAs4 := dstIPPort.Addr().As4()
	ipFields := &header.IPv4Fields{
		SrcAddr:     tcpip.AddrFromSlice(srcAs4[:]),
		DstAddr:     tcpip.AddrFromSlice(dstAs4[:]),
		Protocol:    unix.IPPROTO_UDP,
		TTL:         64,
		TotalLength: uint16(totalLen),
	}
	if ipFn != nil {
		ipFn(ipFields)
	}
	ipv4H.Encode(ipFields)
	udpH := header.UDP(b[offset+20:])
	udpH.Encode(&header.UDPFields{
		SrcPort: srcIPPort.Port(),
		DstPort: dstIPPort.Port(),
		Length:  uint16(payloadLen + udphLen),
	})
	ipv4H.SetChecksum(^ipv4H.CalculateChecksum())
	pseudoCsum := header.PseudoHeaderChecksum(unix.IPPROTO_UDP, ipv4H.SourceAddress(), ipv4H.DestinationAddress(), uint16(udphLen+payloadLen))
	udpH.SetChecksum(^udpH.CalculateChecksum(pseudoCsum))
	return b
}

func udp6Packet(srcIPPort, dstIPPort netip.AddrPort, payloadLen int) []byte {
	return udp6PacketMutateIPFields(srcIPPort, dstIPPort, payloadLen, nil)
}

func udp6PacketMutateIPFields(srcIPPort, dstIPPort netip.AddrPort, payloadLen int, ipFn func(*header.IPv6Fields)) []byte {
	totalLen := 48 + payloadLen
	b := make([]byte, offset+int(totalLen), 65535)
	ipv6H := header.IPv6(b[offset:])
	srcAs16 := srcIPPort.Addr().As16()
	dstAs16 := dstIPPort.Addr().As16()
	ipFields := &header.IPv6Fields{
		SrcAddr:           tcpip.AddrFromSlice(srcAs16[:]),
		DstAddr:           tcpip.AddrFromSlice(dstAs16[:]),
		TransportProtocol: unix.IPPROTO_UDP,
		HopLimit:          64,
		PayloadLength:     uint16(payloadLen + udphLen),
	}
	if ipFn != nil {
		ipFn(ipFields)
	}
	ipv6H.Encode(ipFields)
	udpH := header.UDP(b[offset+40:])
	udpH.Encode(&header.UDPFields{
		SrcPort: srcIPPort.Port(),
		DstPort: dstIPPort.Port(),
		Length:  uint16(payloadLen + udphLen),
	})
	pseudoCsum := header.PseudoHeaderChecksum(unix.IPPROTO_UDP, ipv6H.SourceAddress(), ipv6H.DestinationAddress(), uint16(udphLen+payloadLen))
	udpH.SetChecksum(^udpH.CalculateChecksum(pseudoCsum))
	return b
}

func udp4Packet(srcIPPort, dstIPPort netip.AddrPort, payloadLen int) []byte {
	return udp4PacketMutateIPFields(srcIPPort, dstIPPort, payloadLen, nil)
}

func tcp4PacketMutateIPFields(srcIPPort, dstIPPort netip.AddrPort, flags header.TCPFlags, segmentSize, seq uint32, ipFn func(*header.IPv4Fields)) []byte {
	totalLen := 40 + segmentSize
	b := make([]byte, offset+int(totalLen), 65535)
	ipv4H := header.IPv4(b[offset:])
	srcAs4 := srcIPPort.Addr().As4()
	dstAs4 := dstIPPort.Addr().As4()
	ipFields := &header.IPv4Fields{
		SrcAddr:     tcpip.AddrFromSlice(srcAs4[:]),
		DstAddr:     tcpip.AddrFromSlice(dstAs4[:]),
		Protocol:    unix.IPPROTO_TCP,
		TTL:         64,
		TotalLength: uint16(totalLen),
	}
	if ipFn != nil {
		ipFn(ipFields)
	}
	ipv4H.Encode(ipFields)
	tcpH := header.TCP(b[offset+20:])
	tcpH.Encode(&header.TCPFields{
		SrcPort:    srcIPPort.Port(),
		DstPort:    dstIPPort.Port(),
		SeqNum:     seq,
		AckNum:     1,
		DataOffset: 20,
		Flags:      flags,
		WindowSize: 3000,
	})
	ipv4H.SetChecksum(^ipv4H.CalculateChecksum())
	pseudoCsum := header.PseudoHeaderChecksum(unix.IPPROTO_TCP, ipv4H.SourceAddress(), ipv4H.DestinationAddress(), uint16(20+segmentSize))
	tcpH.SetChecksum(^tcpH.CalculateChecksum(pseudoCsum))
	return b
}

func tcp4Packet(srcIPPort, dstIPPort netip.AddrPort, flags header.TCPFlags, segmentSize, seq uint32) []byte {
	return tcp4PacketMutateIPFields(srcIPPort, dstIPPort, flags, segmentSize, seq, nil)
}

func tcp6PacketMutateIPFields(srcIPPort, dstIPPort netip.AddrPort, flags header.TCPFlags, segmentSize, seq uint32, ipFn func(*header.IPv6Fields)) []byte {
	totalLen := 60 + segmentSize
	b := make([]byte, offset+int(totalLen), 65535)
	ipv6H := header.IPv6(b[offset:])
	srcAs16 := srcIPPort.Addr().As16()
	dstAs16 := dstIPPort.Addr().As16()
	ipFields := &header.IPv6Fields{
		SrcAddr:           tcpip.AddrFromSlice(srcAs16[:]),
		DstAddr:           tcpip.AddrFromSlice(dstAs16[:]),
		TransportProtocol: unix.IPPROTO_TCP,
		HopLimit:          64,
		PayloadLength:     uint16(segmentSize + 20),
	}
	if ipFn != nil {
		ipFn(ipFields)
	}
	ipv6H.Encode(ipFields)
	tcpH := header.TCP(b[offset+40:])
	tcpH.Encode(&header.TCPFields{
		SrcPort:    srcIPPort.Port(),
		DstPort:    dstIPPort.Port(),
		SeqNum:     seq,
		AckNum:     1,
		DataOffset: 20,
		Flags:      flags,
		WindowSize: 3000,
	})
	pseudoCsum := header.PseudoHeaderChecksum(unix.IPPROTO_TCP, ipv6H.SourceAddress(), ipv6H.DestinationAddress(), uint16(20+segmentSize))
	tcpH.SetChecksum(^tcpH.CalculateChecksum(pseudoCsum))
	return b
}

func tcp6Packet(srcIPPort, dstIPPort netip.AddrPort, flags header.TCPFlags, segmentSize, seq uint32) []byte {
	return tcp6PacketMutateIPFields(srcIPPort, dstIPPort, flags, segmentSize, seq, nil)
}

func Test_handleVirtioRead(t *testing.T) {
	tests := []struct {
		name     string
		hdr      virtioNetHdr
		pktIn    []byte
		wantLens []int
		wantErr  bool
	}{
		{
			"tcp4",
			virtioNetHdr{
				flags:      unix.VIRTIO_NET_HDR_F_NEEDS_CSUM,
				gsoType:    unix.VIRTIO_NET_HDR_GSO_TCPV4,
				gsoSize:    100,
				hdrLen:     40,
				csumStart:  20,
				csumOffset: 16,
			},
			tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck|header.TCPFlagPsh, 200, 1),
			[]int{140, 140},
			false,
		},
		{
			"tcp6",
			virtioNetHdr{
				flags:      unix.VIRTIO_NET_HDR_F_NEEDS_CSUM,
				gsoType:    unix.VIRTIO_NET_HDR_GSO_TCPV6,
				gsoSize:    100,
				hdrLen:     60,
				csumStart:  40,
				csumOffset: 16,
			},
			tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck|header.TCPFlagPsh, 200, 1),
			[]int{160, 160},
			false,
		},
		{
			"udp4",
			virtioNetHdr{
				flags:      unix.VIRTIO_NET_HDR_F_NEEDS_CSUM,
				gsoType:    unix.VIRTIO_NET_HDR_GSO_UDP_L4,
				gsoSize:    100,
				hdrLen:     28,
				csumStart:  20,
				csumOffset: 6,
			},
			udp4Packet(ip4PortA, ip4PortB, 200),
			[]int{128, 128},
			false,
		},
		{
			"udp6",
			virtioNetHdr{
				flags:      unix.VIRTIO_NET_HDR_F_NEEDS_CSUM,
				gsoType:    unix.VIRTIO_NET_HDR_GSO_UDP_L4,
				gsoSize:    100,
				hdrLen:     48,
				csumStart:  40,
				csumOffset: 6,
			},
			udp6Packet(ip6PortA, ip6PortB, 200),
			[]int{148, 148},
			false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			out := make([][]byte, conn.IdealBatchSize)
			sizes := make([]int, conn.IdealBatchSize)
			for i := range out {
				out[i] = make([]byte, 65535)
			}
			tt.hdr.encode(tt.pktIn)
			n, err := handleVirtioRead(tt.pktIn, out, sizes, offset)
			if err != nil {
				if tt.wantErr {
					return
				}
				t.Fatalf("got err: %v", err)
			}
			if n != len(tt.wantLens) {
				t.Fatalf("got %d packets, wanted %d", n, len(tt.wantLens))
			}
			for i := range tt.wantLens {
				if tt.wantLens[i] != sizes[i] {
					t.Fatalf("wantLens[%d]: %d != outSizes: %d", i, tt.wantLens[i], sizes[i])
				}
			}
		})
	}
}

func flipTCP4Checksum(b []byte) []byte {
	at := virtioNetHdrLen + 20 + 16 // 20 byte ipv4 header; tcp csum offset is 16
	b[at] ^= 0xFF
	b[at+1] ^= 0xFF
	return b
}

func flipUDP4Checksum(b []byte) []byte {
	at := virtioNetHdrLen + 20 + 6 // 20 byte ipv4 header; udp csum offset is 6
	b[at] ^= 0xFF
	b[at+1] ^= 0xFF
	return b
}

func Fuzz_handleGRO(f *testing.F) {
	pkt0 := tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1)
	pkt1 := tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 101)
	pkt2 := tcp4Packet(ip4PortA, ip4PortC, header.TCPFlagAck, 100, 201)
	pkt3 := tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 1)
	pkt4 := tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 101)
	pkt5 := tcp6Packet(ip6PortA, ip6PortC, header.TCPFlagAck, 100, 201)
	pkt6 := udp4Packet(ip4PortA, ip4PortB, 100)
	pkt7 := udp4Packet(ip4PortA, ip4PortB, 100)
	pkt8 := udp4Packet(ip4PortA, ip4PortC, 100)
	pkt9 := udp6Packet(ip6PortA, ip6PortB, 100)
	pkt10 := udp6Packet(ip6PortA, ip6PortB, 100)
	pkt11 := udp6Packet(ip6PortA, ip6PortC, 100)
	f.Add(pkt0, pkt1, pkt2, pkt3, pkt4, pkt5, pkt6, pkt7, pkt8, pkt9, pkt10, pkt11, true, offset)
	f.Fuzz(func(t *testing.T, pkt0, pkt1, pkt2, pkt3, pkt4, pkt5, pkt6, pkt7, pkt8, pkt9, pkt10, pkt11 []byte, canUDPGRO bool, offset int) {
		pkts := [][]byte{pkt0, pkt1, pkt2, pkt3, pkt4, pkt5, pkt6, pkt7, pkt8, pkt9, pkt10, pkt11}
		toWrite := make([]int, 0, len(pkts))
		handleGRO(pkts, offset, newTCPGROTable(), newUDPGROTable(), canUDPGRO, &toWrite)
		if len(toWrite) > len(pkts) {
			t.Errorf("len(toWrite): %d > len(pkts): %d", len(toWrite), len(pkts))
		}
		seenWriteI := make(map[int]bool)
		for _, writeI := range toWrite {
			if writeI < 0 || writeI > len(pkts)-1 {
				t.Errorf("toWrite value (%d) outside bounds of len(pkts): %d", writeI, len(pkts))
			}
			if seenWriteI[writeI] {
				t.Errorf("duplicate toWrite value: %d", writeI)
			}
			seenWriteI[writeI] = true
		}
	})
}

func Test_handleGRO(t *testing.T) {
	tests := []struct {
		name        string
		pktsIn      [][]byte
		canUDPGRO   bool
		wantToWrite []int
		wantLens    []int
		wantErr     bool
	}{
		{
			"multiple protocols and flows",
			[][]byte{
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1),   // tcp4 flow 1
				udp4Packet(ip4PortA, ip4PortB, 100),                         // udp4 flow 1
				udp4Packet(ip4PortA, ip4PortC, 100),                         // udp4 flow 2
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 101), // tcp4 flow 1
				tcp4Packet(ip4PortA, ip4PortC, header.TCPFlagAck, 100, 201), // tcp4 flow 2
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 1),   // tcp6 flow 1
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 101), // tcp6 flow 1
				tcp6Packet(ip6PortA, ip6PortC, header.TCPFlagAck, 100, 201), // tcp6 flow 2
				udp4Packet(ip4PortA, ip4PortB, 100),                         // udp4 flow 1
				udp6Packet(ip6PortA, ip6PortB, 100),                         // udp6 flow 1
				udp6Packet(ip6PortA, ip6PortB, 100),                         // udp6 flow 1
			},
			true,
			[]int{0, 1, 2, 4, 5, 7, 9},
			[]int{240, 228, 128, 140, 260, 160, 248},
			false,
		},
		{
			"multiple protocols and flows no UDP GRO",
			[][]byte{
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1),   // tcp4 flow 1
				udp4Packet(ip4PortA, ip4PortB, 100),                         // udp4 flow 1
				udp4Packet(ip4PortA, ip4PortC, 100),                         // udp4 flow 2
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 101), // tcp4 flow 1
				tcp4Packet(ip4PortA, ip4PortC, header.TCPFlagAck, 100, 201), // tcp4 flow 2
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 1),   // tcp6 flow 1
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 101), // tcp6 flow 1
				tcp6Packet(ip6PortA, ip6PortC, header.TCPFlagAck, 100, 201), // tcp6 flow 2
				udp4Packet(ip4PortA, ip4PortB, 100),                         // udp4 flow 1
				udp6Packet(ip6PortA, ip6PortB, 100),                         // udp6 flow 1
				udp6Packet(ip6PortA, ip6PortB, 100),                         // udp6 flow 1
			},
			false,
			[]int{0, 1, 2, 4, 5, 7, 8, 9, 10},
			[]int{240, 128, 128, 140, 260, 160, 128, 148, 148},
			false,
		},
		{
			"PSH interleaved",
			[][]byte{
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1),                     // v4 flow 1
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck|header.TCPFlagPsh, 100, 101), // v4 flow 1
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 201),                   // v4 flow 1
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 301),                   // v4 flow 1
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 1),                     // v6 flow 1
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck|header.TCPFlagPsh, 100, 101), // v6 flow 1
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 201),                   // v6 flow 1
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 301),                   // v6 flow 1
			},
			true,
			[]int{0, 2, 4, 6},
			[]int{240, 240, 260, 260},
			false,
		},
		{
			"coalesceItemInvalidCSum",
			[][]byte{
				flipTCP4Checksum(tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1)), // v4 flow 1 seq 1 len 100
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 101),                 // v4 flow 1 seq 101 len 100
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 201),                 // v4 flow 1 seq 201 len 100
				flipUDP4Checksum(udp4Packet(ip4PortA, ip4PortB, 100)),
				udp4Packet(ip4PortA, ip4PortB, 100),
				udp4Packet(ip4PortA, ip4PortB, 100),
			},
			true,
			[]int{0, 1, 3, 4},
			[]int{140, 240, 128, 228},
			false,
		},
		{
			"out of order",
			[][]byte{
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 101), // v4 flow 1 seq 101 len 100
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1),   // v4 flow 1 seq 1 len 100
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 201), // v4 flow 1 seq 201 len 100
			},
			true,
			[]int{0},
			[]int{340},
			false,
		},
		{
			"unequal TTL",
			[][]byte{
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1),
				tcp4PacketMutateIPFields(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 101, func(fields *header.IPv4Fields) {
					fields.TTL++
				}),
				udp4Packet(ip4PortA, ip4PortB, 100),
				udp4PacketMutateIPFields(ip4PortA, ip4PortB, 100, func(fields *header.IPv4Fields) {
					fields.TTL++
				}),
			},
			true,
			[]int{0, 1, 2, 3},
			[]int{140, 140, 128, 128},
			false,
		},
		{
			"unequal ToS",
			[][]byte{
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1),
				tcp4PacketMutateIPFields(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 101, func(fields *header.IPv4Fields) {
					fields.TOS++
				}),
				udp4Packet(ip4PortA, ip4PortB, 100),
				udp4PacketMutateIPFields(ip4PortA, ip4PortB, 100, func(fields *header.IPv4Fields) {
					fields.TOS++
				}),
			},
			true,
			[]int{0, 1, 2, 3},
			[]int{140, 140, 128, 128},
			false,
		},
		{
			"unequal flags more fragments set",
			[][]byte{
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1),
				tcp4PacketMutateIPFields(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 101, func(fields *header.IPv4Fields) {
					fields.Flags = 1
				}),
				udp4Packet(ip4PortA, ip4PortB, 100),
				udp4PacketMutateIPFields(ip4PortA, ip4PortB, 100, func(fields *header.IPv4Fields) {
					fields.Flags = 1
				}),
			},
			true,
			[]int{0, 1, 2, 3},
			[]int{140, 140, 128, 128},
			false,
		},
		{
			"unequal flags DF set",
			[][]byte{
				tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1),
				tcp4PacketMutateIPFields(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 101, func(fields *header.IPv4Fields) {
					fields.Flags = 2
				}),
				udp4Packet(ip4PortA, ip4PortB, 100),
				udp4PacketMutateIPFields(ip4PortA, ip4PortB, 100, func(fields *header.IPv4Fields) {
					fields.Flags = 2
				}),
			},
			true,
			[]int{0, 1, 2, 3},
			[]int{140, 140, 128, 128},
			false,
		},
		{
			"ipv6 unequal hop limit",
			[][]byte{
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 1),
				tcp6PacketMutateIPFields(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 101, func(fields *header.IPv6Fields) {
					fields.HopLimit++
				}),
				udp6Packet(ip6PortA, ip6PortB, 100),
				udp6PacketMutateIPFields(ip6PortA, ip6PortB, 100, func(fields *header.IPv6Fields) {
					fields.HopLimit++
				}),
			},
			true,
			[]int{0, 1, 2, 3},
			[]int{160, 160, 148, 148},
			false,
		},
		{
			"ipv6 unequal traffic class",
			[][]byte{
				tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 1),
				tcp6PacketMutateIPFields(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 101, func(fields *header.IPv6Fields) {
					fields.TrafficClass++
				}),
				udp6Packet(ip6PortA, ip6PortB, 100),
				udp6PacketMutateIPFields(ip6PortA, ip6PortB, 100, func(fields *header.IPv6Fields) {
					fields.TrafficClass++
				}),
			},
			true,
			[]int{0, 1, 2, 3},
			[]int{160, 160, 148, 148},
			false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			toWrite := make([]int, 0, len(tt.pktsIn))
			err := handleGRO(tt.pktsIn, offset, newTCPGROTable(), newUDPGROTable(), tt.canUDPGRO, &toWrite)
			if err != nil {
				if tt.wantErr {
					return
				}
				t.Fatalf("got err: %v", err)
			}
			if len(toWrite) != len(tt.wantToWrite) {
				t.Fatalf("got %d packets, wanted %d", len(toWrite), len(tt.wantToWrite))
			}
			for i, pktI := range tt.wantToWrite {
				if tt.wantToWrite[i] != toWrite[i] {
					t.Fatalf("wantToWrite[%d]: %d != toWrite: %d", i, tt.wantToWrite[i], toWrite[i])
				}
				if tt.wantLens[i] != len(tt.pktsIn[pktI][offset:]) {
					t.Errorf("wanted len %d packet at %d, got: %d", tt.wantLens[i], i, len(tt.pktsIn[pktI][offset:]))
				}
			}
		})
	}
}

func Test_packetIsGROCandidate(t *testing.T) {
	tcp4 := tcp4Packet(ip4PortA, ip4PortB, header.TCPFlagAck, 100, 1)[virtioNetHdrLen:]
	tcp4TooShort := tcp4[:39]
	ip4InvalidHeaderLen := make([]byte, len(tcp4))
	copy(ip4InvalidHeaderLen, tcp4)
	ip4InvalidHeaderLen[0] = 0x46
	ip4InvalidProtocol := make([]byte, len(tcp4))
	copy(ip4InvalidProtocol, tcp4)
	ip4InvalidProtocol[9] = unix.IPPROTO_GRE

	tcp6 := tcp6Packet(ip6PortA, ip6PortB, header.TCPFlagAck, 100, 1)[virtioNetHdrLen:]
	tcp6TooShort := tcp6[:59]
	ip6InvalidProtocol := make([]byte, len(tcp6))
	copy(ip6InvalidProtocol, tcp6)
	ip6InvalidProtocol[6] = unix.IPPROTO_GRE

	udp4 := udp4Packet(ip4PortA, ip4PortB, 100)[virtioNetHdrLen:]
	udp4TooShort := udp4[:27]

	udp6 := udp6Packet(ip6PortA, ip6PortB, 100)[virtioNetHdrLen:]
	udp6TooShort := udp6[:47]

	tests := []struct {
		name      string
		b         []byte
		canUDPGRO bool
		want      groCandidateType
	}{
		{
			"tcp4",
			tcp4,
			true,
			tcp4GROCandidate,
		},
		{
			"tcp6",
			tcp6,
			true,
			tcp6GROCandidate,
		},
		{
			"udp4",
			udp4,
			true,
			udp4GROCandidate,
		},
		{
			"udp4 no support",
			udp4,
			false,
			notGROCandidate,
		},
		{
			"udp6",
			udp6,
			true,
			udp6GROCandidate,
		},
		{
			"udp6 no support",
			udp6,
			false,
			notGROCandidate,
		},
		{
			"udp4 too short",
			udp4TooShort,
			true,
			notGROCandidate,
		},
		{
			"udp6 too short",
			udp6TooShort,
			true,
			notGROCandidate,
		},
		{
			"tcp4 too short",
			tcp4TooShort,
			true,
			notGROCandidate,
		},
		{
			"tcp6 too short",
			tcp6TooShort,
			true,
			notGROCandidate,
		},
		{
			"invalid IP version",
			[]byte{0x00},
			true,
			notGROCandidate,
		},
		{
			"invalid IP header len",
			ip4InvalidHeaderLen,
			true,
			notGROCandidate,
		},
		{
			"ip4 invalid protocol",
			ip4InvalidProtocol,
			true,
			notGROCandidate,
		},
		{
			"ip6 invalid protocol",
			ip6InvalidProtocol,
			true,
			notGROCandidate,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := packetIsGROCandidate(tt.b, tt.canUDPGRO); got != tt.want {
				t.Errorf("packetIsGROCandidate() = %v, want %v", got, tt.want)
			}
		})
	}
}

func Test_udpPacketsCanCoalesce(t *testing.T) {
	udp4a := udp4Packet(ip4PortA, ip4PortB, 100)
	udp4b := udp4Packet(ip4PortA, ip4PortB, 100)
	udp4c := udp4Packet(ip4PortA, ip4PortB, 110)

	type args struct {
		pkt        []byte
		iphLen     uint8
		gsoSize    uint16
		item       udpGROItem
		bufs       [][]byte
		bufsOffset int
	}
	tests := []struct {
		name string
		args args
		want canCoalesce
	}{
		{
			"coalesceAppend equal gso",
			args{
				pkt:     udp4a[offset:],
				iphLen:  20,
				gsoSize: 100,
				item: udpGROItem{
					gsoSize: 100,
					iphLen:  20,
				},
				bufs: [][]byte{
					udp4a,
					udp4b,
				},
				bufsOffset: offset,
			},
			coalesceAppend,
		},
		{
			"coalesceAppend smaller gso",
			args{
				pkt:     udp4a[offset : len(udp4a)-90],
				iphLen:  20,
				gsoSize: 10,
				item: udpGROItem{
					gsoSize: 100,
					iphLen:  20,
				},
				bufs: [][]byte{
					udp4a,
					udp4b,
				},
				bufsOffset: offset,
			},
			coalesceAppend,
		},
		{
			"coalesceUnavailable smaller gso previously appended",
			args{
				pkt:     udp4a[offset:],
				iphLen:  20,
				gsoSize: 100,
				item: udpGROItem{
					gsoSize: 100,
					iphLen:  20,
				},
				bufs: [][]byte{
					udp4c,
					udp4b,
				},
				bufsOffset: offset,
			},
			coalesceUnavailable,
		},
		{
			"coalesceUnavailable larger following smaller",
			args{
				pkt:     udp4c[offset:],
				iphLen:  20,
				gsoSize: 110,
				item: udpGROItem{
					gsoSize: 100,
					iphLen:  20,
				},
				bufs: [][]byte{
					udp4a,
					udp4c,
				},
				bufsOffset: offset,
			},
			coalesceUnavailable,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := udpPacketsCanCoalesce(tt.args.pkt, tt.args.iphLen, tt.args.gsoSize, tt.args.item, tt.args.bufs, tt.args.bufsOffset); got != tt.want {
				t.Errorf("udpPacketsCanCoalesce() = %v, want %v", got, tt.want)
			}
		})
	}
}
