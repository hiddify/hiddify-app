/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package device

import (
	"math/rand"
	"net/netip"
)

type DummyEndpoint struct {
	src, dst netip.Addr
}

func CreateDummyEndpoint() (*DummyEndpoint, error) {
	var src, dst [16]byte
	if _, err := rand.Read(src[:]); err != nil {
		return nil, err
	}
	_, err := rand.Read(dst[:])
	return &DummyEndpoint{netip.AddrFrom16(src), netip.AddrFrom16(dst)}, err
}

func (e *DummyEndpoint) ClearSrc() {}

func (e *DummyEndpoint) SrcToString() string {
	return netip.AddrPortFrom(e.SrcIP(), 1000).String()
}

func (e *DummyEndpoint) DstToString() string {
	return netip.AddrPortFrom(e.DstIP(), 1000).String()
}

func (e *DummyEndpoint) DstToBytes() []byte {
	out := e.DstIP().AsSlice()
	out = append(out, byte(1000&0xff))
	out = append(out, byte((1000>>8)&0xff))
	return out
}

func (e *DummyEndpoint) DstIP() netip.Addr {
	return e.dst
}

func (e *DummyEndpoint) SrcIP() netip.Addr {
	return e.src
}
