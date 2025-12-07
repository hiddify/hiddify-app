/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package tun

import (
	"reflect"
	"testing"
	"unsafe"
)

func checkAlignment(t *testing.T, name string, offset uintptr) {
	t.Helper()
	if offset%8 != 0 {
		t.Errorf("offset of %q within struct is %d bytes, which does not align to 64-bit word boundaries (missing %d bytes). Atomic operations will crash on 32-bit systems.", name, offset, 8-(offset%8))
	}
}

// TestRateJugglerAlignment checks that atomically-accessed fields are
// aligned to 64-bit boundaries, as required by the atomic package.
//
// Unfortunately, violating this rule on 32-bit platforms results in a
// hard segfault at runtime.
func TestRateJugglerAlignment(t *testing.T) {
	var r rateJuggler

	typ := reflect.TypeOf(&r).Elem()
	t.Logf("Peer type size: %d, with fields:", typ.Size())
	for i := 0; i < typ.NumField(); i++ {
		field := typ.Field(i)
		t.Logf("\t%30s\toffset=%3v\t(type size=%3d, align=%d)",
			field.Name,
			field.Offset,
			field.Type.Size(),
			field.Type.Align(),
		)
	}

	checkAlignment(t, "rateJuggler.current", unsafe.Offsetof(r.current))
	checkAlignment(t, "rateJuggler.nextByteCount", unsafe.Offsetof(r.nextByteCount))
	checkAlignment(t, "rateJuggler.nextStartTime", unsafe.Offsetof(r.nextStartTime))
}

// TestNativeTunAlignment checks that atomically-accessed fields are
// aligned to 64-bit boundaries, as required by the atomic package.
//
// Unfortunately, violating this rule on 32-bit platforms results in a
// hard segfault at runtime.
func TestNativeTunAlignment(t *testing.T) {
	var tun NativeTun

	typ := reflect.TypeOf(&tun).Elem()
	t.Logf("Peer type size: %d, with fields:", typ.Size())
	for i := 0; i < typ.NumField(); i++ {
		field := typ.Field(i)
		t.Logf("\t%30s\toffset=%3v\t(type size=%3d, align=%d)",
			field.Name,
			field.Offset,
			field.Type.Size(),
			field.Type.Align(),
		)
	}

	checkAlignment(t, "NativeTun.rate", unsafe.Offsetof(tun.rate))
}
