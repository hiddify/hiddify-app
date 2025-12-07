//go:build ignore

/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package main

import (
	"io"
	"log"
	"net/http"
	"net/netip"

	"github.com/bepass-org/vwarp/wireguard/conn"
	"github.com/bepass-org/vwarp/wireguard/device"
	"github.com/bepass-org/vwarp/wireguard/tun/netstack"
)

func main() {
	tun, tnet, err := netstack.CreateNetTUN(
		[]netip.Addr{netip.MustParseAddr("192.168.4.28")},
		[]netip.Addr{netip.MustParseAddr("8.8.8.8")},
		1420)
	if err != nil {
		log.Panic(err)
	}
	dev := device.NewDevice(tun, conn.NewDefaultBind(), device.NewLogger(device.LogLevelVerbose, ""))
	err = dev.IpcSet(`private_key=087ec6e14bbed210e7215cdc73468dfa23f080a1bfb8665b2fd809bd99d28379
public_key=c4c8e984c5322c8184c72265b92b250fdb63688705f504ba003c88f03393cf28
allowed_ip=0.0.0.0/0
endpoint=127.0.0.1:58120
`)
	err = dev.Up()
	if err != nil {
		log.Panic(err)
	}

	client := http.Client{
		Transport: &http.Transport{
			DialContext: tnet.DialContext,
		},
	}
	resp, err := client.Get("http://192.168.4.29/")
	if err != nil {
		log.Panic(err)
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Panic(err)
	}
	log.Println(string(body))
}
