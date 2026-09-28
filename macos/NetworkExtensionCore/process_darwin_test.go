package tunnel

import (
	"net"
	"os"
	"path/filepath"
	"syscall"
	"testing"
)

func TestFindConnectionOwner(t *testing.T) {
	executable, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	executable, err = filepath.EvalSymlinks(executable)
	if err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		network string
		address string
	}{
		{"tcp4", "127.0.0.1:0"},
		{"tcp6", "[::1]:0"},
		{"udp4", "127.0.0.1:0"},
		{"udp6", "[::1]:0"},
		{"udp4", "0.0.0.0:0"},
		{"udp6", "[::]:0"},
	} {
		t.Run(tc.network+"/"+tc.address, func(t *testing.T) {
			var source net.IP
			var port int
			var protocol int32
			if tc.network[:3] == "tcp" {
				listener, err := net.Listen(tc.network, tc.address)
				if err != nil {
					t.Fatal(err)
				}
				defer listener.Close()
				connection, err := net.Dial(tc.network, listener.Addr().String())
				if err != nil {
					t.Fatal(err)
				}
				defer connection.Close()
				address := connection.LocalAddr().(*net.TCPAddr)
				source, port, protocol = address.IP, address.Port, syscall.IPPROTO_TCP
			} else {
				connection, err := net.ListenPacket(tc.network, tc.address)
				if err != nil {
					t.Fatal(err)
				}
				defer connection.Close()
				address := connection.LocalAddr().(*net.UDPAddr)
				source, port, protocol = address.IP, address.Port, syscall.IPPROTO_UDP
				if source.IsUnspecified() {
					if tc.network == "udp4" {
						source = net.ParseIP("127.0.0.1")
					} else {
						source = net.ParseIP("::1")
					}
				}
			}
			owner, err := FindConnectionOwner(protocol, source.String(), int32(port))
			if err != nil {
				t.Fatal(err)
			}
			if owner.ProcessPath != executable {
				t.Fatalf("process path = %q, want %q", owner.ProcessPath, executable)
			}
			if owner.UserId != -1 {
				t.Fatalf("user ID = %d, want -1 for Darwin's path-only lookup", owner.UserId)
			}
		})
	}
}

func TestFindConnectionOwnerRejectsInvalidSource(t *testing.T) {
	for _, tc := range []struct {
		protocol int32
		address  string
		port     int32
	}{
		{syscall.IPPROTO_ICMP, "127.0.0.1", 1234},
		{syscall.IPPROTO_TCP, "", 1234},
		{syscall.IPPROTO_TCP, "invalid", 1234},
		{syscall.IPPROTO_TCP, "127.0.0.1", -1},
		{syscall.IPPROTO_TCP, "127.0.0.1", 0},
		{syscall.IPPROTO_UDP, "127.0.0.1", 65536},
	} {
		if owner, err := FindConnectionOwner(tc.protocol, tc.address, tc.port); err == nil || owner != nil {
			t.Errorf("FindConnectionOwner(%d, %q, %d) = %v, %v; want an error", tc.protocol, tc.address, tc.port, owner, err)
		}
	}
}
