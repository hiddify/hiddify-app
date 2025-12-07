package wiresocks

import (
	"bytes"
	"context"
	"errors"
	"log/slog"
	"strings"
	"testing"
	"time"
)

// testWriter is a helper that wraps t.Logf to implement the io.Writer interface.
type testWriter struct {
	t *testing.T
}

func (tw testWriter) Write(p []byte) (n int, err error) {
	tw.t.Logf("%v\n", string(bytes.TrimSpace(p)))
	return len(p), nil
}

// newTestLogger creates a logger that prints to the test's output.
func newTestLogger(t *testing.T) *slog.Logger {
	return slog.New(slog.NewTextHandler(testWriter{t}, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}))
}

// TestRunScanEndpointParsing validates that the endpoint string parsing within RunScan behaves correctly.
// Test logic that configures the scanner.
func TestRunScanEndpointParsing(t *testing.T) {
	dummyPrivateKey := "yGXeX7gMyUIZmK5QIgC7+XX5USUSskQvBYiQ6LdkiXI="
	dummyPublicKey := "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="

	testCases := []struct {
		name             string
		endpoints        string
		expectParseError bool
		expectedErrorMsg string
	}{
		{
			name:             "Valid Domain",
			endpoints:        "engage.cloudflareclient.com",
			expectParseError: false,
		},
		{
			name:             "Valid CIDR",
			endpoints:        "192.168.1.0/24",
			expectParseError: false,
		},
		{
			name:             "Valid Single IP",
			endpoints:        "8.8.8.8",
			expectParseError: false,
		},
		{
			name:             "Valid IP with Port",
			endpoints:        "1.1.1.1:500",
			expectParseError: false,
		},
		{
			name:             "Valid Domain with Port",
			endpoints:        "one.one.one.one:8443",
			expectParseError: false,
		},
		{
			name:             "Multiple Valid Endpoints",
			endpoints:        "1.1.1.1, 192.168.1.0/24, engage.cloudflareclient.com",
			expectParseError: false,
		},
		{
			name:             "Multiple Valid Endpoints with spaces",
			endpoints:        " 8.8.8.8:500 ,  10.0.0.0/8 ",
			expectParseError: false,
		},
		{
			name:             "Empty Endpoint String",
			endpoints:        "",
			expectParseError: false, // Should be ignored gracefully
		},
		{
			name:             "Empty Parts with Commas",
			endpoints:        "1.1.1.1,,8.8.8.8",
			expectParseError: false, // Empty parts should be ignored
		},
		{
			name:             "Invalid Endpoint String",
			endpoints:        "not-a-valid-endpoint",
			expectParseError: true,
			expectedErrorMsg: "invalid endpoint format: not-a-valid-endpoint",
		},
		{
			name:             "Invalid IP with Port (port too high)",
			endpoints:        "1.2.3.4:99999",
			expectParseError: true,
			expectedErrorMsg: "invalid port number: 99999",
		},
		{
			name:             "Invalid IP with Port (non-numeric port)",
			endpoints:        "1.2.3.4:abc",
			expectParseError: true,
			expectedErrorMsg: "invalid port number: abc",
		},
		{
			name:             "Partially Invalid Endpoint",
			endpoints:        "1.1.1.1, invalid-string, 8.8.8.8",
			expectParseError: true,
			expectedErrorMsg: "invalid endpoint format: invalid-string",
		},
		{
			name:             "Invalid CIDR",
			endpoints:        "192.168.1.0/33",
			expectParseError: true,
			expectedErrorMsg: "invalid endpoint format: 192.168.1.0/33",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			opts := ScanOptions{
				Endpoints:  tc.endpoints,
				PrivateKey: dummyPrivateKey,
				PublicKey:  dummyPublicKey,
				V4:         true,
			}

			// We use a very short timeout. This is the key to the test.
			// It's long enough for the parsing logic to run, but short enough
			// to cancel the actual network scan before it can complete.
			// Can be increased to see the logs...
			ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
			defer cancel()

			_, err := RunScan(ctx, newTestLogger(t), opts)

			if tc.expectParseError {
				if err == nil {
					t.Fatal("expected a parsing error but got nil")
				}
				if !strings.Contains(err.Error(), tc.expectedErrorMsg) {
					t.Errorf("expected error message to contain %q, but got %q", tc.expectedErrorMsg, err.Error())
				}
			} else {
				t.Logf("Error: %v", err)
				// For valid inputs, we expect one of two outcomes:
				// 1. A context timeout error (most likely).
				// 2. A "no working IPs found" error if the scan finishes within the timeout.
				// Any other error (especially a parsing error) indicates a failure.
				if err != nil && !errors.Is(err, context.DeadlineExceeded) && !strings.Contains(err.Error(), "no working IPs found") {
					t.Fatalf("did not expect a parsing error, but got: %v", err)
				}
			}
		})
	}
}
