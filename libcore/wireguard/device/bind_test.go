/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package device

import (
	"errors"

	"github.com/bepass-org/vwarp/wireguard/conn"
)

type DummyDatagram struct {
	msg      []byte
	endpoint conn.Endpoint
}

type DummyBind struct {
	in6    chan DummyDatagram
	in4    chan DummyDatagram
	closed bool
}

func (b *DummyBind) SetMark(v uint32) error {
	return nil
}

func (b *DummyBind) ReceiveIPv6(buf []byte) (int, conn.Endpoint, error) {
	datagram, ok := <-b.in6
	if !ok {
		return 0, nil, errors.New("closed")
	}
	copy(buf, datagram.msg)
	return len(datagram.msg), datagram.endpoint, nil
}

func (b *DummyBind) ReceiveIPv4(buf []byte) (int, conn.Endpoint, error) {
	datagram, ok := <-b.in4
	if !ok {
		return 0, nil, errors.New("closed")
	}
	copy(buf, datagram.msg)
	return len(datagram.msg), datagram.endpoint, nil
}

func (b *DummyBind) Close() error {
	close(b.in6)
	close(b.in4)
	b.closed = true
	return nil
}

func (b *DummyBind) Send(buf []byte, end conn.Endpoint) error {
	return nil
}
