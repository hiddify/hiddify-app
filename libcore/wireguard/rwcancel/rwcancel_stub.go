//go:build windows || wasm

// SPDX-License-Identifier: MIT

package rwcancel

type RWCancel struct{}

func (*RWCancel) Cancel() {}
