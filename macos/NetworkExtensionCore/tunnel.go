// Package tunnel hosts the core in a macOS packet-tunnel system extension.
// Lifecycle and configuration changes go through NetworkExtension, while the
// authenticated loopback service exposes the existing statistics/proxy APIs.
package tunnel

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"fmt"
	"net"
	"strconv"
	"sync"

	"github.com/hiddify/hiddify-core/v2/hcore"
	"github.com/hiddify/hiddify-core/v2/hello"
	_ "github.com/sagernet/gomobile"
	"github.com/sagernet/sing-box/experimental/libbox"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

type Options struct {
	BasePath           string
	WorkingPath        string
	TempPath           string
	ConfigContent      string
	ConfigName         string
	SettingsJSON       string
	Secret             string
	Port               int32
	DisableMemoryLimit bool
}

var lifecycle sync.Mutex
var server *grpc.Server

func authenticate(ctx context.Context, secret string) error {
	md, _ := metadata.FromIncomingContext(ctx)
	values := md.Get("x-hiddify-secret")
	if len(values) != 1 || subtle.ConstantTimeCompare([]byte(values[0]), []byte(secret)) != 1 {
		return status.Error(codes.Unauthenticated, "invalid extension credentials")
	}
	return nil
}

func allowMethod(method string) error {
	// Expose only observability and proxy selection. Lifecycle, file paths and
	// system proxy settings must never reach the privileged engine over gRPC.
	switch method {
	case "/hello.Hello/SayHello", hcore.Core_CoreInfoListener_FullMethodName,
		hcore.Core_OutboundsInfo_FullMethodName, hcore.Core_MainOutboundsInfo_FullMethodName,
		hcore.Core_GetSystemInfo_FullMethodName, hcore.Core_GetSystemInfoStream_FullMethodName,
		hcore.Core_LogListener_FullMethodName, hcore.Core_SelectOutbound_FullMethodName,
		hcore.Core_UrlTest_FullMethodName, hcore.Core_UrlTestActive_FullMethodName:
		return nil
	}
	return status.Error(codes.PermissionDenied, "use NetworkExtension to change the tunnel")
}

// Start completes only after the engine has applied the tunnel network settings.
func Start(options *Options, platform libbox.PlatformInterface) (err error) {
	lifecycle.Lock()
	defer lifecycle.Unlock()
	if options == nil || platform == nil || len(options.Secret) < 32 || options.ConfigContent == "" {
		return fmt.Errorf("missing tunnel configuration or credentials")
	}
	if options.Port < 1024 || options.Port > 65535 {
		return fmt.Errorf("invalid control port")
	}
	if server != nil {
		return fmt.Errorf("tunnel already running")
	}
	// Reserve the port before installing any routes; never attach to another app.
	listener, err := net.Listen("tcp", net.JoinHostPort("127.0.0.1", strconv.Itoa(int(options.Port))))
	if err != nil {
		return err
	}
	defer func() {
		if err != nil {
			listener.Close()
			hcore.Stop()
		}
	}()
	// The core's legacy mode initializes the engine without starting an insecure
	// control server. This wrapper supplies its own authenticated gRPC server.
	err = hcore.Setup(&hcore.SetupRequest{
		BasePath: options.BasePath, WorkingDir: options.WorkingPath,
		TempDir: options.TempPath, Mode: hcore.SetupMode_OLD, Debug: false,
	}, platform)
	if err != nil {
		return err
	}
	var settings map[string]any
	if err = json.Unmarshal([]byte(options.SettingsJSON), &settings); err != nil {
		return err
	}
	// VPN mode must not install a separate system proxy or a privileged listener
	// on the LAN, even if those options came from a custom profile.
	settings["enable-tun"] = true
	settings["enable-tun-service"] = false
	settings["set-system-proxy"] = false
	settings["allow-connection-from-lan"] = false
	settings["tproxy-port"] = 0
	settingsBytes, err := json.Marshal(settings)
	if err != nil {
		return err
	}
	if _, err = hcore.ChangeHiddifySettings(&hcore.ChangeHiddifySettingsRequest{
		HiddifySettingsJson: string(settingsBytes),
	}, false); err != nil {
		return err
	}
	if _, err = hcore.StartService(libbox.BaseContext(platform), &hcore.StartRequest{
		ConfigContent: options.ConfigContent, ConfigName: options.ConfigName,
		DisableMemoryLimit: options.DisableMemoryLimit,
	}); err != nil {
		return err
	}
	server = grpc.NewServer(
		grpc.UnaryInterceptor(func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
			if err := authenticate(ctx, options.Secret); err != nil {
				return nil, err
			}
			if err := allowMethod(info.FullMethod); err != nil {
				return nil, err
			}
			return handler(ctx, req)
		}),
		grpc.StreamInterceptor(func(srv any, stream grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
			if err := authenticate(stream.Context(), options.Secret); err != nil {
				return err
			}
			if err := allowMethod(info.FullMethod); err != nil {
				return err
			}
			return handler(srv, stream)
		}),
	)
	hcore.RegisterCoreServer(server, &hcore.CoreService{})
	hello.RegisterHelloServer(server, &hello.HelloService{})
	controlServer := server
	go controlServer.Serve(listener)
	return nil
}

func Stop() error {
	lifecycle.Lock()
	defer lifecycle.Unlock()
	if server != nil {
		server.Stop()
		server = nil
	}
	_, err := hcore.Stop()
	return err
}

func Pause() { hcore.Pause() }
func Wake()  { hcore.Wake() }
