/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package conn

import (
	"syscall"

	"golang.org/x/sys/windows"
)

func init() {
	controlFns = append(controlFns,
		func(network, address string, c syscall.RawConn) error {
			return c.Control(func(fd uintptr) {
				_ = windows.SetsockoptInt(windows.Handle(fd), windows.SOL_SOCKET, windows.SO_RCVBUF, socketBufferSize)
				_ = windows.SetsockoptInt(windows.Handle(fd), windows.SOL_SOCKET, windows.SO_SNDBUF, socketBufferSize)
			})
		},
	)
}
