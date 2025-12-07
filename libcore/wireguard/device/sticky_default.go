//go:build !linux

package device

import (
	"github.com/bepass-org/vwarp/wireguard/conn"
	"github.com/bepass-org/vwarp/wireguard/rwcancel"
)

func (device *Device) startRouteListener(bind conn.Bind) (*rwcancel.RWCancel, error) {
	return nil, nil
}
