/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package conn

import (
	"fmt"
	"runtime"
	"syscall"

	"golang.org/x/sys/unix"
)

func init() {
	controlFns = append(controlFns,

		// Attempt to set the socket buffer size beyond net.core.{r,w}mem_max by
		// using SO_*BUFFORCE. This requires CAP_NET_ADMIN, and is allowed here to
		// fail silently - the result of failure is lower performance on very fast
		// links or high latency links.
		func(network, address string, c syscall.RawConn) error {
			return c.Control(func(fd uintptr) {
				// Set up to *mem_max
				_ = unix.SetsockoptInt(int(fd), unix.SOL_SOCKET, unix.SO_RCVBUF, socketBufferSize)
				_ = unix.SetsockoptInt(int(fd), unix.SOL_SOCKET, unix.SO_SNDBUF, socketBufferSize)
				// Set beyond *mem_max if CAP_NET_ADMIN
				_ = unix.SetsockoptInt(int(fd), unix.SOL_SOCKET, unix.SO_RCVBUFFORCE, socketBufferSize)
				_ = unix.SetsockoptInt(int(fd), unix.SOL_SOCKET, unix.SO_SNDBUFFORCE, socketBufferSize)
			})
		},

		// Enable receiving of the packet information (IP_PKTINFO for IPv4,
		// IPV6_PKTINFO for IPv6) that is used to implement sticky socket support.
		func(network, address string, c syscall.RawConn) error {
			var err error
			switch network {
			case "udp4":
				if runtime.GOOS != "android" {
					c.Control(func(fd uintptr) {
						err = unix.SetsockoptInt(int(fd), unix.IPPROTO_IP, unix.IP_PKTINFO, 1)
					})
				}
			case "udp6":
				c.Control(func(fd uintptr) {
					if runtime.GOOS != "android" {
						err = unix.SetsockoptInt(int(fd), unix.IPPROTO_IPV6, unix.IPV6_RECVPKTINFO, 1)
						if err != nil {
							return
						}
					}
					err = unix.SetsockoptInt(int(fd), unix.IPPROTO_IPV6, unix.IPV6_V6ONLY, 1)
				})
			default:
				err = fmt.Errorf("unhandled network: %s: %w", network, unix.EINVAL)
			}
			return err
		},

		// Attempt to enable UDP_GRO
		func(network, address string, c syscall.RawConn) error {
			c.Control(func(fd uintptr) {
				_ = unix.SetsockoptInt(int(fd), unix.IPPROTO_UDP, unix.UDP_GRO, 1)
			})
			return nil
		},
	)
}
