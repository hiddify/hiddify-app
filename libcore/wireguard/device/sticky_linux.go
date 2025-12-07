/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 *
 * This implements userspace semantics of "sticky sockets", modeled after
 * WireGuard's kernelspace implementation. This is more or less a straight port
 * of the sticky-sockets.c example code:
 * https://git.zx2c4.com/WireGuard/tree/contrib/examples/sticky-sockets/sticky-sockets.c
 *
 * Currently there is no way to achieve this within the net package:
 * See e.g. https://github.com/golang/go/issues/17930
 * So this code is remains platform dependent.
 */

package device

import (
	"sync"
	"unsafe"

	"golang.org/x/sys/unix"

	"github.com/bepass-org/vwarp/wireguard/conn"
	"github.com/bepass-org/vwarp/wireguard/rwcancel"
)

func (device *Device) startRouteListener(bind conn.Bind) (*rwcancel.RWCancel, error) {
	if !conn.StdNetSupportsStickySockets {
		return nil, nil
	}
	if _, ok := bind.(*conn.StdNetBind); !ok {
		return nil, nil
	}

	netlinkSock, err := createNetlinkRouteSocket()
	if err != nil {
		return nil, err
	}
	netlinkCancel, err := rwcancel.NewRWCancel(netlinkSock)
	if err != nil {
		unix.Close(netlinkSock)
		return nil, err
	}

	go device.routineRouteListener(bind, netlinkSock, netlinkCancel)

	return netlinkCancel, nil
}

func (device *Device) routineRouteListener(bind conn.Bind, netlinkSock int, netlinkCancel *rwcancel.RWCancel) {
	type peerEndpointPtr struct {
		peer     *Peer
		endpoint *conn.Endpoint
	}
	var reqPeer map[uint32]peerEndpointPtr
	var reqPeerLock sync.Mutex

	defer netlinkCancel.Close()
	defer unix.Close(netlinkSock)

	for msg := make([]byte, 1<<16); ; {
		var err error
		var msgn int
		for {
			msgn, _, _, _, err = unix.Recvmsg(netlinkSock, msg[:], nil, 0)
			if err == nil || !rwcancel.RetryAfterError(err) {
				break
			}
			if !netlinkCancel.ReadyRead() {
				return
			}
		}
		if err != nil {
			return
		}

		for remain := msg[:msgn]; len(remain) >= unix.SizeofNlMsghdr; {

			hdr := *(*unix.NlMsghdr)(unsafe.Pointer(&remain[0]))

			if uint(hdr.Len) > uint(len(remain)) {
				break
			}

			switch hdr.Type {
			case unix.RTM_NEWROUTE, unix.RTM_DELROUTE:
				if hdr.Seq <= MaxPeers && hdr.Seq > 0 {
					if uint(len(remain)) < uint(hdr.Len) {
						break
					}
					if hdr.Len > unix.SizeofNlMsghdr+unix.SizeofRtMsg {
						attr := remain[unix.SizeofNlMsghdr+unix.SizeofRtMsg:]
						for {
							if uint(len(attr)) < uint(unix.SizeofRtAttr) {
								break
							}
							attrhdr := *(*unix.RtAttr)(unsafe.Pointer(&attr[0]))
							if attrhdr.Len < unix.SizeofRtAttr || uint(len(attr)) < uint(attrhdr.Len) {
								break
							}
							if attrhdr.Type == unix.RTA_OIF && attrhdr.Len == unix.SizeofRtAttr+4 {
								ifidx := *(*uint32)(unsafe.Pointer(&attr[unix.SizeofRtAttr]))
								reqPeerLock.Lock()
								if reqPeer == nil {
									reqPeerLock.Unlock()
									break
								}
								pePtr, ok := reqPeer[hdr.Seq]
								reqPeerLock.Unlock()
								if !ok {
									break
								}
								pePtr.peer.endpoint.Lock()
								if &pePtr.peer.endpoint.val != pePtr.endpoint {
									pePtr.peer.endpoint.Unlock()
									break
								}
								if uint32(pePtr.peer.endpoint.val.(*conn.StdNetEndpoint).SrcIfidx()) == ifidx {
									pePtr.peer.endpoint.Unlock()
									break
								}
								pePtr.peer.endpoint.clearSrcOnTx = true
								pePtr.peer.endpoint.Unlock()
							}
							attr = attr[attrhdr.Len:]
						}
					}
					break
				}
				reqPeerLock.Lock()
				reqPeer = make(map[uint32]peerEndpointPtr)
				reqPeerLock.Unlock()
				go func() {
					device.peers.RLock()
					i := uint32(1)
					for _, peer := range device.peers.keyMap {
						peer.endpoint.Lock()
						if peer.endpoint.val == nil {
							peer.endpoint.Unlock()
							continue
						}
						nativeEP, _ := peer.endpoint.val.(*conn.StdNetEndpoint)
						if nativeEP == nil {
							peer.endpoint.Unlock()
							continue
						}
						if nativeEP.DstIP().Is6() || nativeEP.SrcIfidx() == 0 {
							peer.endpoint.Unlock()
							break
						}
						nlmsg := struct {
							hdr     unix.NlMsghdr
							msg     unix.RtMsg
							dsthdr  unix.RtAttr
							dst     [4]byte
							srchdr  unix.RtAttr
							src     [4]byte
							markhdr unix.RtAttr
							mark    uint32
						}{
							unix.NlMsghdr{
								Type:  uint16(unix.RTM_GETROUTE),
								Flags: unix.NLM_F_REQUEST,
								Seq:   i,
							},
							unix.RtMsg{
								Family:  unix.AF_INET,
								Dst_len: 32,
								Src_len: 32,
							},
							unix.RtAttr{
								Len:  8,
								Type: unix.RTA_DST,
							},
							nativeEP.DstIP().As4(),
							unix.RtAttr{
								Len:  8,
								Type: unix.RTA_SRC,
							},
							nativeEP.SrcIP().As4(),
							unix.RtAttr{
								Len:  8,
								Type: unix.RTA_MARK,
							},
							device.net.fwmark,
						}
						nlmsg.hdr.Len = uint32(unsafe.Sizeof(nlmsg))
						reqPeerLock.Lock()
						reqPeer[i] = peerEndpointPtr{
							peer:     peer,
							endpoint: &peer.endpoint.val,
						}
						reqPeerLock.Unlock()
						peer.endpoint.Unlock()
						i++
						_, err := netlinkCancel.Write((*[unsafe.Sizeof(nlmsg)]byte)(unsafe.Pointer(&nlmsg))[:])
						if err != nil {
							break
						}
					}
					device.peers.RUnlock()
				}()
			}
			remain = remain[hdr.Len:]
		}
	}
}

func createNetlinkRouteSocket() (int, error) {
	sock, err := unix.Socket(unix.AF_NETLINK, unix.SOCK_RAW|unix.SOCK_CLOEXEC, unix.NETLINK_ROUTE)
	if err != nil {
		return -1, err
	}
	saddr := &unix.SockaddrNetlink{
		Family: unix.AF_NETLINK,
		Groups: unix.RTMGRP_IPV4_ROUTE,
	}
	err = unix.Bind(sock, saddr)
	if err != nil {
		unix.Close(sock)
		return -1, err
	}
	return sock, nil
}
