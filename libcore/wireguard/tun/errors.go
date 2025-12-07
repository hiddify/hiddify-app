package tun

import (
	"errors"
)

var (
	// ErrTooManySegments is returned by Device.Read() when segmentation
	// overflows the length of supplied buffers. This error should not cause
	// reads to cease.
	ErrTooManySegments = errors.New("too many segments")
)
