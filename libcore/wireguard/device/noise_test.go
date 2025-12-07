/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package device

import (
	"bytes"
	"encoding/binary"
	"testing"

	"github.com/bepass-org/vwarp/wireguard/conn"
	"github.com/bepass-org/vwarp/wireguard/tun/tuntest"
)

func TestCurveWrappers(t *testing.T) {
	sk1, err := newPrivateKey()
	assertNil(t, err)

	sk2, err := newPrivateKey()
	assertNil(t, err)

	pk1 := sk1.publicKey()
	pk2 := sk2.publicKey()

	ss1, err1 := sk1.sharedSecret(pk2)
	ss2, err2 := sk2.sharedSecret(pk1)

	if ss1 != ss2 || err1 != nil || err2 != nil {
		t.Fatal("Failed to compute shared secet")
	}
}

func randDevice(t *testing.T) *Device {
	sk, err := newPrivateKey()
	if err != nil {
		t.Fatal(err)
	}
	tun := tuntest.NewChannelTUN()
	logger := NewLogger(LogLevelError, "")
	device := NewDevice(tun.TUN(), conn.NewDefaultBind(), logger)
	device.SetPrivateKey(sk)
	return device
}

func assertNil(t *testing.T, err error) {
	if err != nil {
		t.Fatal(err)
	}
}

func assertEqual(t *testing.T, a, b []byte) {
	if !bytes.Equal(a, b) {
		t.Fatal(a, "!=", b)
	}
}

func TestNoiseHandshake(t *testing.T) {
	dev1 := randDevice(t)
	dev2 := randDevice(t)

	defer dev1.Close()
	defer dev2.Close()

	peer1, err := dev2.NewPeer(dev1.staticIdentity.privateKey.publicKey())
	if err != nil {
		t.Fatal(err)
	}
	peer2, err := dev1.NewPeer(dev2.staticIdentity.privateKey.publicKey())
	if err != nil {
		t.Fatal(err)
	}
	peer1.Start()
	peer2.Start()

	assertEqual(
		t,
		peer1.handshake.precomputedStaticStatic[:],
		peer2.handshake.precomputedStaticStatic[:],
	)

	/* simulate handshake */

	// initiation message

	t.Log("exchange initiation message")

	msg1, err := dev1.CreateMessageInitiation(peer2)
	assertNil(t, err)

	packet := make([]byte, 0, 256)
	writer := bytes.NewBuffer(packet)
	err = binary.Write(writer, binary.LittleEndian, msg1)
	assertNil(t, err)
	peer := dev2.ConsumeMessageInitiation(msg1)
	if peer == nil {
		t.Fatal("handshake failed at initiation message")
	}

	assertEqual(
		t,
		peer1.handshake.chainKey[:],
		peer2.handshake.chainKey[:],
	)

	assertEqual(
		t,
		peer1.handshake.hash[:],
		peer2.handshake.hash[:],
	)

	// response message

	t.Log("exchange response message")

	msg2, err := dev2.CreateMessageResponse(peer1)
	assertNil(t, err)

	peer = dev1.ConsumeMessageResponse(msg2)
	if peer == nil {
		t.Fatal("handshake failed at response message")
	}

	assertEqual(
		t,
		peer1.handshake.chainKey[:],
		peer2.handshake.chainKey[:],
	)

	assertEqual(
		t,
		peer1.handshake.hash[:],
		peer2.handshake.hash[:],
	)

	// key pairs

	t.Log("deriving keys")

	err = peer1.BeginSymmetricSession()
	if err != nil {
		t.Fatal("failed to derive keypair for peer 1", err)
	}

	err = peer2.BeginSymmetricSession()
	if err != nil {
		t.Fatal("failed to derive keypair for peer 2", err)
	}

	key1 := peer1.keypairs.next.Load()
	key2 := peer2.keypairs.current

	// encrypting / decryption test

	t.Log("test key pairs")

	func() {
		testMsg := []byte("wireguard test message 1")
		var err error
		var out []byte
		var nonce [12]byte
		out = key1.send.Seal(out, nonce[:], testMsg, nil)
		out, err = key2.receive.Open(out[:0], nonce[:], out, nil)
		assertNil(t, err)
		assertEqual(t, out, testMsg)
	}()

	func() {
		testMsg := []byte("wireguard test message 2")
		var err error
		var out []byte
		var nonce [12]byte
		out = key2.send.Seal(out, nonce[:], testMsg, nil)
		out, err = key1.receive.Open(out[:0], nonce[:], out, nil)
		assertNil(t, err)
		assertEqual(t, out, testMsg)
	}()
}
