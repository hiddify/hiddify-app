/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package conn

import (
	"net"

	"golang.org/x/sys/unix"
)

func supportsUDPOffload(conn *net.UDPConn) (txOffload, rxOffload bool) {
	rc, err := conn.SyscallConn()
	if err != nil {
		return
	}
	err = rc.Control(func(fd uintptr) {
		_, errSyscall := unix.GetsockoptInt(int(fd), unix.IPPROTO_UDP, unix.UDP_SEGMENT)
		txOffload = errSyscall == nil
		opt, errSyscall := unix.GetsockoptInt(int(fd), unix.IPPROTO_UDP, unix.UDP_GRO)
		rxOffload = errSyscall == nil && opt == 1
	})
	if err != nil {
		return false, false
	}
	return txOffload, rxOffload
}
