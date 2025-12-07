/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package device

import "github.com/bepass-org/vwarp/wireguard/conn"

/* Reduce memory consumption for Android */

const (
	QueueStagedSize            = conn.IdealBatchSize
	QueueOutboundSize          = 1024
	QueueInboundSize           = 1024
	QueueHandshakeSize         = 1024
	MaxSegmentSize             = (1 << 16) - 1 // largest possible UDP datagram
	PreallocatedBuffersPerPool = 4096
)
