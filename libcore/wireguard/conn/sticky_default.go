//go:build !linux || android

/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package conn

import "net/netip"

func (e *StdNetEndpoint) SrcIP() netip.Addr {
	return netip.Addr{}
}

func (e *StdNetEndpoint) SrcIfidx() int32 {
	return 0
}

func (e *StdNetEndpoint) SrcToString() string {
	return ""
}

// TODO: macOS, FreeBSD and other BSDs likely do support the sticky sockets
// {get,set}srcControl feature set, but use alternatively named flags and need
// ports and require testing.

// getSrcFromControl parses the control for PKTINFO and if found updates ep with
// the source information found.
func getSrcFromControl(control []byte, ep *StdNetEndpoint) {
}

// setSrcControl parses the control for PKTINFO and if found updates ep with
// the source information found.
func setSrcControl(control *[]byte, ep *StdNetEndpoint) {
}

// stickyControlSize returns the recommended buffer size for pooling sticky
// offloading control data.
const stickyControlSize = 0

const StdNetSupportsStickySockets = false
