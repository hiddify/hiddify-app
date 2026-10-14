package tunnel

import (
	"context"
	"testing"

	"github.com/hiddify/hiddify-core/v2/hcore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

func TestControlAuthentication(t *testing.T) {
	secret := "test-credentials-longer-than-thirty-two-characters"
	for _, tc := range []struct {
		name   string
		values []string
		want   codes.Code
	}{
		{"missing", nil, codes.Unauthenticated},
		{"incorrect", []string{"incorrect"}, codes.Unauthenticated},
		{"duplicate", []string{secret, secret}, codes.Unauthenticated},
		{"authenticated", []string{secret}, codes.OK},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx := metadata.NewIncomingContext(context.Background(), metadata.MD{"x-hiddify-secret": tc.values})
			if got := status.Code(authenticate(ctx, secret)); got != tc.want {
				t.Fatalf("authentication = %v, want %v", got, tc.want)
			}
		})
	}
}

func TestControlCannotChangePrivilegedConfiguration(t *testing.T) {
	for _, method := range []string{
		hcore.Core_Start_FullMethodName, hcore.Core_Stop_FullMethodName,
		hcore.Core_Restart_FullMethodName, hcore.Core_Setup_FullMethodName,
		hcore.Core_Parse_FullMethodName, hcore.Core_ChangeHiddifySettings_FullMethodName,
		hcore.Core_Close_FullMethodName, hcore.Core_SetSystemProxyEnabled_FullMethodName,
		"/unknown.Service/Method",
	} {
		if got := status.Code(allowMethod(method)); got != codes.PermissionDenied {
			t.Errorf("%s = %v, want permission denied", method, got)
		}
	}
	for _, method := range []string{hcore.Core_GetSystemInfoStream_FullMethodName, hcore.Core_SelectOutbound_FullMethodName} {
		if err := allowMethod(method); err != nil {
			t.Errorf("%s: %v", method, err)
		}
	}
}
