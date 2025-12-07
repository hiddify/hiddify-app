// Copyright 2021 The Go Authors. All rights reserved.
// Copyright 2015 Microsoft
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build windows

package namedpipe_test

import (
	"bufio"
	"bytes"
	"context"
	"errors"
	"io"
	"net"
	"os"
	"sync"
	"syscall"
	"testing"
	"time"

	"github.com/bepass-org/vwarp/wireguard/ipc/namedpipe"
	"golang.org/x/sys/windows"
)

func randomPipePath() string {
	guid, err := windows.GenerateGUID()
	if err != nil {
		panic(err)
	}
	return `\\.\PIPE\go-namedpipe-test-` + guid.String()
}

func TestPingPong(t *testing.T) {
	const (
		ping = 42
		pong = 24
	)
	pipePath := randomPipePath()
	listener, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatalf("unable to listen on pipe: %v", err)
	}
	defer listener.Close()
	go func() {
		incoming, err := listener.Accept()
		if err != nil {
			t.Fatalf("unable to accept pipe connection: %v", err)
		}
		defer incoming.Close()
		var data [1]byte
		_, err = incoming.Read(data[:])
		if err != nil {
			t.Fatalf("unable to read ping from pipe: %v", err)
		}
		if data[0] != ping {
			t.Fatalf("expected ping, got %d", data[0])
		}
		data[0] = pong
		_, err = incoming.Write(data[:])
		if err != nil {
			t.Fatalf("unable to write pong to pipe: %v", err)
		}
	}()
	client, err := namedpipe.DialTimeout(pipePath, time.Duration(0))
	if err != nil {
		t.Fatalf("unable to dial pipe: %v", err)
	}
	defer client.Close()
	client.SetDeadline(time.Now().Add(time.Second * 5))
	var data [1]byte
	data[0] = ping
	_, err = client.Write(data[:])
	if err != nil {
		t.Fatalf("unable to write ping to pipe: %v", err)
	}
	_, err = client.Read(data[:])
	if err != nil {
		t.Fatalf("unable to read pong from pipe: %v", err)
	}
	if data[0] != pong {
		t.Fatalf("expected pong, got %d", data[0])
	}
}

func TestDialUnknownFailsImmediately(t *testing.T) {
	_, err := namedpipe.DialTimeout(randomPipePath(), time.Duration(0))
	if !errors.Is(err, syscall.ENOENT) {
		t.Fatalf("expected ENOENT got %v", err)
	}
}

func TestDialListenerTimesOut(t *testing.T) {
	pipePath := randomPipePath()
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	pipe, err := namedpipe.DialTimeout(pipePath, 10*time.Millisecond)
	if err == nil {
		pipe.Close()
	}
	if err != os.ErrDeadlineExceeded {
		t.Fatalf("expected os.ErrDeadlineExceeded, got %v", err)
	}
}

func TestDialContextListenerTimesOut(t *testing.T) {
	pipePath := randomPipePath()
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	d := 10 * time.Millisecond
	ctx, _ := context.WithTimeout(context.Background(), d)
	pipe, err := namedpipe.DialContext(ctx, pipePath)
	if err == nil {
		pipe.Close()
	}
	if err != context.DeadlineExceeded {
		t.Fatalf("expected context.DeadlineExceeded, got %v", err)
	}
}

func TestDialListenerGetsCancelled(t *testing.T) {
	pipePath := randomPipePath()
	ctx, cancel := context.WithCancel(context.Background())
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	ch := make(chan error)
	go func(ctx context.Context, ch chan error) {
		_, err := namedpipe.DialContext(ctx, pipePath)
		ch <- err
	}(ctx, ch)
	time.Sleep(time.Millisecond * 30)
	cancel()
	err = <-ch
	if err != context.Canceled {
		t.Fatalf("expected context.Canceled, got %v", err)
	}
}

func TestDialAccessDeniedWithRestrictedSD(t *testing.T) {
	if windows.NewLazySystemDLL("ntdll.dll").NewProc("wine_get_version").Find() == nil {
		t.Skip("dacls on named pipes are broken on wine")
	}
	pipePath := randomPipePath()
	sd, _ := windows.SecurityDescriptorFromString("D:")
	l, err := (&namedpipe.ListenConfig{
		SecurityDescriptor: sd,
	}).Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	pipe, err := namedpipe.DialTimeout(pipePath, time.Duration(0))
	if err == nil {
		pipe.Close()
	}
	if !errors.Is(err, windows.ERROR_ACCESS_DENIED) {
		t.Fatalf("expected ERROR_ACCESS_DENIED, got %v", err)
	}
}

func getConnection(cfg *namedpipe.ListenConfig) (client, server net.Conn, err error) {
	pipePath := randomPipePath()
	if cfg == nil {
		cfg = &namedpipe.ListenConfig{}
	}
	l, err := cfg.Listen(pipePath)
	if err != nil {
		return
	}
	defer l.Close()

	type response struct {
		c   net.Conn
		err error
	}
	ch := make(chan response)
	go func() {
		c, err := l.Accept()
		ch <- response{c, err}
	}()

	c, err := namedpipe.DialTimeout(pipePath, time.Duration(0))
	if err != nil {
		return
	}

	r := <-ch
	if err = r.err; err != nil {
		c.Close()
		return
	}

	client = c
	server = r.c
	return
}

func TestReadTimeout(t *testing.T) {
	c, s, err := getConnection(nil)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	defer s.Close()

	c.SetReadDeadline(time.Now().Add(10 * time.Millisecond))

	buf := make([]byte, 10)
	_, err = c.Read(buf)
	if err != os.ErrDeadlineExceeded {
		t.Fatalf("expected os.ErrDeadlineExceeded, got %v", err)
	}
}

func server(l net.Listener, ch chan int) {
	c, err := l.Accept()
	if err != nil {
		panic(err)
	}
	rw := bufio.NewReadWriter(bufio.NewReader(c), bufio.NewWriter(c))
	s, err := rw.ReadString('\n')
	if err != nil {
		panic(err)
	}
	_, err = rw.WriteString("got " + s)
	if err != nil {
		panic(err)
	}
	err = rw.Flush()
	if err != nil {
		panic(err)
	}
	c.Close()
	ch <- 1
}

func TestFullListenDialReadWrite(t *testing.T) {
	pipePath := randomPipePath()
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()

	ch := make(chan int)
	go server(l, ch)

	c, err := namedpipe.DialTimeout(pipePath, time.Duration(0))
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()

	rw := bufio.NewReadWriter(bufio.NewReader(c), bufio.NewWriter(c))
	_, err = rw.WriteString("hello world\n")
	if err != nil {
		t.Fatal(err)
	}
	err = rw.Flush()
	if err != nil {
		t.Fatal(err)
	}

	s, err := rw.ReadString('\n')
	if err != nil {
		t.Fatal(err)
	}
	ms := "got hello world\n"
	if s != ms {
		t.Errorf("expected '%s', got '%s'", ms, s)
	}

	<-ch
}

func TestCloseAbortsListen(t *testing.T) {
	pipePath := randomPipePath()
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}

	ch := make(chan error)
	go func() {
		_, err := l.Accept()
		ch <- err
	}()

	time.Sleep(30 * time.Millisecond)
	l.Close()

	err = <-ch
	if err != net.ErrClosed {
		t.Fatalf("expected net.ErrClosed, got %v", err)
	}
}

func ensureEOFOnClose(t *testing.T, r io.Reader, w io.Closer) {
	b := make([]byte, 10)
	w.Close()
	n, err := r.Read(b)
	if n > 0 {
		t.Errorf("unexpected byte count %d", n)
	}
	if err != io.EOF {
		t.Errorf("expected EOF: %v", err)
	}
}

func TestCloseClientEOFServer(t *testing.T) {
	c, s, err := getConnection(nil)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	defer s.Close()
	ensureEOFOnClose(t, c, s)
}

func TestCloseServerEOFClient(t *testing.T) {
	c, s, err := getConnection(nil)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	defer s.Close()
	ensureEOFOnClose(t, s, c)
}

func TestCloseWriteEOF(t *testing.T) {
	cfg := &namedpipe.ListenConfig{
		MessageMode: true,
	}
	c, s, err := getConnection(cfg)
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	defer s.Close()

	type closeWriter interface {
		CloseWrite() error
	}

	err = c.(closeWriter).CloseWrite()
	if err != nil {
		t.Fatal(err)
	}

	b := make([]byte, 10)
	_, err = s.Read(b)
	if err != io.EOF {
		t.Fatal(err)
	}
}

func TestAcceptAfterCloseFails(t *testing.T) {
	pipePath := randomPipePath()
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	l.Close()
	_, err = l.Accept()
	if err != net.ErrClosed {
		t.Fatalf("expected net.ErrClosed, got %v", err)
	}
}

func TestDialTimesOutByDefault(t *testing.T) {
	pipePath := randomPipePath()
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	pipe, err := namedpipe.DialTimeout(pipePath, time.Duration(0)) // Should timeout after 2 seconds.
	if err == nil {
		pipe.Close()
	}
	if err != os.ErrDeadlineExceeded {
		t.Fatalf("expected os.ErrDeadlineExceeded, got %v", err)
	}
}

func TestTimeoutPendingRead(t *testing.T) {
	pipePath := randomPipePath()
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()

	serverDone := make(chan struct{})

	go func() {
		s, err := l.Accept()
		if err != nil {
			t.Fatal(err)
		}
		time.Sleep(1 * time.Second)
		s.Close()
		close(serverDone)
	}()

	client, err := namedpipe.DialTimeout(pipePath, time.Duration(0))
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()

	clientErr := make(chan error)
	go func() {
		buf := make([]byte, 10)
		_, err = client.Read(buf)
		clientErr <- err
	}()

	time.Sleep(100 * time.Millisecond) // make *sure* the pipe is reading before we set the deadline
	client.SetReadDeadline(time.Unix(1, 0))

	select {
	case err = <-clientErr:
		if err != os.ErrDeadlineExceeded {
			t.Fatalf("expected os.ErrDeadlineExceeded, got %v", err)
		}
	case <-time.After(100 * time.Millisecond):
		t.Fatalf("timed out while waiting for read to cancel")
		<-clientErr
	}
	<-serverDone
}

func TestTimeoutPendingWrite(t *testing.T) {
	pipePath := randomPipePath()
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()

	serverDone := make(chan struct{})

	go func() {
		s, err := l.Accept()
		if err != nil {
			t.Fatal(err)
		}
		time.Sleep(1 * time.Second)
		s.Close()
		close(serverDone)
	}()

	client, err := namedpipe.DialTimeout(pipePath, time.Duration(0))
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()

	clientErr := make(chan error)
	go func() {
		_, err = client.Write([]byte("this should timeout"))
		clientErr <- err
	}()

	time.Sleep(100 * time.Millisecond) // make *sure* the pipe is writing before we set the deadline
	client.SetWriteDeadline(time.Unix(1, 0))

	select {
	case err = <-clientErr:
		if err != os.ErrDeadlineExceeded {
			t.Fatalf("expected os.ErrDeadlineExceeded, got %v", err)
		}
	case <-time.After(100 * time.Millisecond):
		t.Fatalf("timed out while waiting for write to cancel")
		<-clientErr
	}
	<-serverDone
}

type CloseWriter interface {
	CloseWrite() error
}

func TestEchoWithMessaging(t *testing.T) {
	pipePath := randomPipePath()
	l, err := (&namedpipe.ListenConfig{
		MessageMode:      true,  // Use message mode so that CloseWrite() is supported
		InputBufferSize:  65536, // Use 64KB buffers to improve performance
		OutputBufferSize: 65536,
	}).Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()

	listenerDone := make(chan bool)
	clientDone := make(chan bool)
	go func() {
		// server echo
		conn, err := l.Accept()
		if err != nil {
			t.Fatal(err)
		}
		defer conn.Close()

		time.Sleep(500 * time.Millisecond) // make *sure* we don't begin to read before eof signal is sent
		_, err = io.Copy(conn, conn)
		if err != nil {
			t.Fatal(err)
		}
		conn.(CloseWriter).CloseWrite()
		close(listenerDone)
	}()
	client, err := namedpipe.DialTimeout(pipePath, time.Second)
	if err != nil {
		t.Fatal(err)
	}
	defer client.Close()

	go func() {
		// client read back
		bytes := make([]byte, 2)
		n, e := client.Read(bytes)
		if e != nil {
			t.Fatal(e)
		}
		if n != 2 || bytes[0] != 0 || bytes[1] != 1 {
			t.Fatalf("expected 2 bytes, got %v", n)
		}
		close(clientDone)
	}()

	payload := make([]byte, 2)
	payload[0] = 0
	payload[1] = 1

	n, err := client.Write(payload)
	if err != nil {
		t.Fatal(err)
	}
	if n != 2 {
		t.Fatalf("expected 2 bytes, got %v", n)
	}
	client.(CloseWriter).CloseWrite()
	<-listenerDone
	<-clientDone
}

func TestConnectRace(t *testing.T) {
	pipePath := randomPipePath()
	l, err := namedpipe.Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	go func() {
		for {
			s, err := l.Accept()
			if err == net.ErrClosed {
				return
			}

			if err != nil {
				t.Fatal(err)
			}
			s.Close()
		}
	}()

	for i := 0; i < 1000; i++ {
		c, err := namedpipe.DialTimeout(pipePath, time.Duration(0))
		if err != nil {
			t.Fatal(err)
		}
		c.Close()
	}
}

func TestMessageReadMode(t *testing.T) {
	if maj, _, _ := windows.RtlGetNtVersionNumbers(); maj <= 8 {
		t.Skipf("Skipping on Windows %d", maj)
	}
	var wg sync.WaitGroup
	defer wg.Wait()
	pipePath := randomPipePath()
	l, err := (&namedpipe.ListenConfig{MessageMode: true}).Listen(pipePath)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()

	msg := ([]byte)("hello world")

	wg.Add(1)
	go func() {
		defer wg.Done()
		s, err := l.Accept()
		if err != nil {
			t.Fatal(err)
		}
		_, err = s.Write(msg)
		if err != nil {
			t.Fatal(err)
		}
		s.Close()
	}()

	c, err := namedpipe.DialTimeout(pipePath, time.Duration(0))
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()

	mode := uint32(windows.PIPE_READMODE_MESSAGE)
	err = windows.SetNamedPipeHandleState(c.(interface{ Handle() windows.Handle }).Handle(), &mode, nil, nil)
	if err != nil {
		t.Fatal(err)
	}

	ch := make([]byte, 1)
	var vmsg []byte
	for {
		n, err := c.Read(ch)
		if err == io.EOF {
			break
		}
		if err != nil {
			t.Fatal(err)
		}
		if n != 1 {
			t.Fatalf("expected 1, got %d", n)
		}
		vmsg = append(vmsg, ch[0])
	}
	if !bytes.Equal(msg, vmsg) {
		t.Fatalf("expected %s, got %s", msg, vmsg)
	}
}

func TestListenConnectRace(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping long race test")
	}
	pipePath := randomPipePath()
	for i := 0; i < 50 && !t.Failed(); i++ {
		var wg sync.WaitGroup
		wg.Add(1)
		go func() {
			c, err := namedpipe.DialTimeout(pipePath, time.Duration(0))
			if err == nil {
				c.Close()
			}
			wg.Done()
		}()
		s, err := namedpipe.Listen(pipePath)
		if err != nil {
			t.Error(i, err)
		} else {
			s.Close()
		}
		wg.Wait()
	}
}
