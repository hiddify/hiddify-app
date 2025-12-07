package statute

import (
	"context"
	"io"
	"net"
	"os"
	"reflect"
	"runtime"
	"strings"
)

// isClosedConnError reports whether err is an error from use of a closed
// network connection.
func isClosedConnError(err error) bool {
	if err == nil {
		return false
	}

	str := err.Error()
	if strings.Contains(str, "use of closed network connection") {
		return true
	}

	if runtime.GOOS == "windows" {
		if oe, ok := err.(*net.OpError); ok && oe.Op == "read" {
			if se, ok := oe.Err.(*os.SyscallError); ok && se.Syscall == "wsarecv" {
				const WSAECONNABORTED = 10053
				const WSAECONNRESET = 10054
				if n := errno(se.Err); n == WSAECONNRESET || n == WSAECONNABORTED {
					return true
				}
			}
		}
	}
	return false
}

func errno(v error) uintptr {
	if rv := reflect.ValueOf(v); rv.Kind() == reflect.Uintptr {
		return uintptr(rv.Uint())
	}
	return 0
}

// Tunnel create tunnels for two io.ReadWriteCloser
func Tunnel(ctx context.Context, c1, c2 io.ReadWriteCloser, buf1, buf2 []byte) error {
	ctx, cancel := context.WithCancel(ctx)
	var errs tunnelErr
	go func() {
		_, errs[0] = io.CopyBuffer(c1, c2, buf1)
		cancel()
	}()
	go func() {
		_, errs[1] = io.CopyBuffer(c2, c1, buf2)
		cancel()
	}()
	<-ctx.Done()
	errs[2] = c1.Close()
	errs[3] = c2.Close()
	errs[4] = ctx.Err()
	if errs[4] == context.Canceled {
		errs[4] = nil
	}
	return errs.FirstError()
}

type tunnelErr [5]error

func (t tunnelErr) FirstError() error {
	for _, err := range t {
		if err != nil {
			if isClosedConnError(err) {
				return nil
			}
			return err
		}
	}
	return nil
}
