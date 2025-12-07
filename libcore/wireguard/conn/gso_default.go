//go:build !linux

/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package conn

// getGSOSize parses control for UDP_GRO and if found returns its GSO size data.
func getGSOSize(control []byte) (int, error) {
	return 0, nil
}

// setGSOSize sets a UDP_SEGMENT in control based on gsoSize.
func setGSOSize(control *[]byte, gsoSize uint16) {
}

// gsoControlSize returns the recommended buffer size for pooling sticky and UDP
// offloading control data.
const gsoControlSize = 0
