//go:build linux

/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package conn

import (
	"fmt"
	"unsafe"

	"golang.org/x/sys/unix"
)

const (
	sizeOfGSOData = 2
)

// getGSOSize parses control for UDP_GRO and if found returns its GSO size data.
func getGSOSize(control []byte) (int, error) {
	var (
		hdr  unix.Cmsghdr
		data []byte
		rem  = control
		err  error
	)

	for len(rem) > unix.SizeofCmsghdr {
		hdr, data, rem, err = unix.ParseOneSocketControlMessage(rem)
		if err != nil {
			return 0, fmt.Errorf("error parsing socket control message: %w", err)
		}
		if hdr.Level == unix.SOL_UDP && hdr.Type == unix.UDP_GRO && len(data) >= sizeOfGSOData {
			var gso uint16
			copy(unsafe.Slice((*byte)(unsafe.Pointer(&gso)), sizeOfGSOData), data[:sizeOfGSOData])
			return int(gso), nil
		}
	}
	return 0, nil
}

// setGSOSize sets a UDP_SEGMENT in control based on gsoSize. It leaves existing
// data in control untouched.
func setGSOSize(control *[]byte, gsoSize uint16) {
	existingLen := len(*control)
	avail := cap(*control) - existingLen
	space := unix.CmsgSpace(sizeOfGSOData)
	if avail < space {
		return
	}
	*control = (*control)[:cap(*control)]
	gsoControl := (*control)[existingLen:]
	hdr := (*unix.Cmsghdr)(unsafe.Pointer(&(gsoControl)[0]))
	hdr.Level = unix.SOL_UDP
	hdr.Type = unix.UDP_SEGMENT
	hdr.SetLen(unix.CmsgLen(sizeOfGSOData))
	copy((gsoControl)[unix.CmsgLen(0):], unsafe.Slice((*byte)(unsafe.Pointer(&gsoSize)), sizeOfGSOData))
	*control = (*control)[:existingLen+space]
}

// gsoControlSize returns the recommended buffer size for pooling UDP
// offloading control data.
var gsoControlSize = unix.CmsgSpace(sizeOfGSOData)
