package psiphon

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/netip"
	"path/filepath"

	"github.com/Psiphon-Labs/psiphon-tunnel-core/psiphon"
)

var Countries = []string{
	"AT",
	"AU",
	"BE",
	"BG",
	"CA",
	"CH",
	"CZ",
	"DE",
	"DK",
	"EE",
	"ES",
	"FI",
	"FR",
	"GB",
	"HR",
	"HU",
	"IE",
	"IN",
	"IT",
	"JP",
	"LV",
	"NL",
	"NO",
	"PL",
	"PT",
	"RO",
	"RS",
	"SE",
	"SG",
	"SK",
	"US",
}

// NoticeEvent represents the notices emitted by tunnel core. It will be passed to
// noticeReceiver, if supplied.
// NOTE: Ordinary users of this library should never need this.
type NoticeEvent struct {
	Data      map[string]interface{} `json:"data"`
	Type      string                 `json:"noticeType"`
	Timestamp string                 `json:"timestamp"`
}

func StartTunnel(ctx context.Context, l *slog.Logger, config *psiphon.Config) error {
	controllerCtx, cancel := context.WithCancel(ctx)
	// config.Commit must be called before calling config.SetParameters
	// or attempting to connect.
	if err := config.Commit(true); err != nil {
		return errors.New("config.Commit failed")
	}

	// Will receive a value when the tunnel has successfully connected.
	connected := make(chan struct{})
	// Will receive a value if an error occurs during the connection sequence.
	errored := make(chan error)

	// Set up notice handling
	psiphon.SetNoticeWriter(psiphon.NewNoticeReceiver(
		func(notice []byte) {
			var event NoticeEvent
			if err := json.Unmarshal(notice, &event); err != nil {
				return
			}

			go func(event NoticeEvent) {
				l.Debug("psiphon core notice", "type", event.Type, "data", event.Data)
				switch event.Type {
				case "EstablishTunnelTimeout":
					select {
					case errored <- errors.New("clientlib: tunnel establishment timeout"):
					default:
					}
				case "Tunnels":
					if event.Data["count"].(float64) > 0 {
						select {
						case connected <- struct{}{}:
						default:
						}
					}
				}
			}(event)
		}))

	if err := psiphon.OpenDataStore(config); err != nil {
		return errors.New("failed to open data store")
	}

	if err := psiphon.ImportEmbeddedServerEntries(controllerCtx, config, "", ""); err != nil {
		return err
	}

	// Create the Psiphon controller
	controller, err := psiphon.NewController(config)
	if err != nil {
		return errors.New("psiphon.NewController failed")
	}

	// Begin tunnel connection
	go func() {
		// Start the tunnel. Only returns on error (or internal timeout).
		controller.Run(controllerCtx)

		select {
		case errored <- errors.New("controller.Run exited unexpectedly"):
		default:
		}
	}()

	// Wait for an active tunnel or error
	select {
	case <-connected:
		return nil
	case err := <-errored:
		cancel()
		psiphon.CloseDataStore()
		psiphon.SetNoticeWriter(io.Discard)
		return err
	}
}

func RunPsiphon(ctx context.Context, l *slog.Logger, wgBind netip.AddrPort, dir string, localSocksAddr netip.AddrPort, country string) error {
	host := ""
	if !netip.MustParsePrefix("127.0.0.0/8").Contains(localSocksAddr.Addr()) {
		host = "any"
	}

	timeout := 60
	config := psiphon.Config{
		EgressRegion:                                 country,
		ListenInterface:                              host,
		LocalSocksProxyPort:                          int(localSocksAddr.Port()),
		UpstreamProxyURL:                             fmt.Sprintf("socks5://%s", wgBind),
		DisableLocalHTTPProxy:                        true,
		PropagationChannelId:                         "FFFFFFFFFFFFFFFF",
		RemoteServerListDownloadFilename:             "remote_server_list",
		RemoteServerListSignaturePublicKey:           "MIICIDANBgkqhkiG9w0BAQEFAAOCAg0AMIICCAKCAgEAt7Ls+/39r+T6zNW7GiVpJfzq/xvL9SBH5rIFnk0RXYEYavax3WS6HOD35eTAqn8AniOwiH+DOkvgSKF2caqk/y1dfq47Pdymtwzp9ikpB1C5OfAysXzBiwVJlCdajBKvBZDerV1cMvRzCKvKwRmvDmHgphQQ7WfXIGbRbmmk6opMBh3roE42KcotLFtqp0RRwLtcBRNtCdsrVsjiI1Lqz/lH+T61sGjSjQ3CHMuZYSQJZo/KrvzgQXpkaCTdbObxHqb6/+i1qaVOfEsvjoiyzTxJADvSytVtcTjijhPEV6XskJVHE1Zgl+7rATr/pDQkw6DPCNBS1+Y6fy7GstZALQXwEDN/qhQI9kWkHijT8ns+i1vGg00Mk/6J75arLhqcodWsdeG/M/moWgqQAnlZAGVtJI1OgeF5fsPpXu4kctOfuZlGjVZXQNW34aOzm8r8S0eVZitPlbhcPiR4gT/aSMz/wd8lZlzZYsje/Jr8u/YtlwjjreZrGRmG8KMOzukV3lLmMppXFMvl4bxv6YFEmIuTsOhbLTwFgh7KYNjodLj/LsqRVfwz31PgWQFTEPICV7GCvgVlPRxnofqKSjgTWI4mxDhBpVcATvaoBl1L/6WLbFvBsoAUBItWwctO2xalKxF5szhGm8lccoc5MZr8kfE0uxMgsxz4er68iCID+rsCAQM=",
		RemoteServerListUrl:                          "https://s3.amazonaws.com//psiphon/web/mjr4-p23r-puwl/server_list_compressed",
		SponsorId:                                    "FFFFFFFFFFFFFFFF",
		NetworkID:                                    "test",
		ClientPlatform:                               "Android_4.0.4_com.example.exampleClientLibraryApp",
		AllowDefaultDNSResolverWithBindToDevice:      true,
		EstablishTunnelTimeoutSeconds:                &timeout,
		DataRootDirectory:                            dir,
		MigrateDataStoreDirectory:                    dir,
		MigrateObfuscatedServerListDownloadDirectory: dir,
		MigrateRemoteServerListDownloadFilename:      filepath.Join(dir, "server_list_compressed"),
	}

	l.Info("starting handshake")
	if err := StartTunnel(ctx, l, &config); err != nil {
		return fmt.Errorf("Unable to start psiphon: %w", err)
	}
	l.Info("psiphon started successfully")
	return nil
}
