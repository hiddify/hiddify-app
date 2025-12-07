/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package ratelimiter

import (
	"net/netip"
	"sync"
	"time"
)

const (
	packetsPerSecond   = 20
	packetsBurstable   = 5
	garbageCollectTime = time.Second
	packetCost         = 1000000000 / packetsPerSecond
	maxTokens          = packetCost * packetsBurstable
)

type RatelimiterEntry struct {
	mu       sync.Mutex
	lastTime time.Time
	tokens   int64
}

type Ratelimiter struct {
	mu      sync.RWMutex
	timeNow func() time.Time

	stopReset chan struct{} // send to reset, close to stop
	table     map[netip.Addr]*RatelimiterEntry
}

func (rate *Ratelimiter) Close() {
	rate.mu.Lock()
	defer rate.mu.Unlock()

	if rate.stopReset != nil {
		close(rate.stopReset)
	}
}

func (rate *Ratelimiter) Init() {
	rate.mu.Lock()
	defer rate.mu.Unlock()

	if rate.timeNow == nil {
		rate.timeNow = time.Now
	}

	// stop any ongoing garbage collection routine
	if rate.stopReset != nil {
		close(rate.stopReset)
	}

	rate.stopReset = make(chan struct{})
	rate.table = make(map[netip.Addr]*RatelimiterEntry)

	stopReset := rate.stopReset // store in case Init is called again.

	// Start garbage collection routine.
	go func() {
		ticker := time.NewTicker(time.Second)
		ticker.Stop()
		for {
			select {
			case _, ok := <-stopReset:
				ticker.Stop()
				if !ok {
					return
				}
				ticker = time.NewTicker(time.Second)
			case <-ticker.C:
				if rate.cleanup() {
					ticker.Stop()
				}
			}
		}
	}()
}

func (rate *Ratelimiter) cleanup() (empty bool) {
	rate.mu.Lock()
	defer rate.mu.Unlock()

	for key, entry := range rate.table {
		entry.mu.Lock()
		if rate.timeNow().Sub(entry.lastTime) > garbageCollectTime {
			delete(rate.table, key)
		}
		entry.mu.Unlock()
	}

	return len(rate.table) == 0
}

func (rate *Ratelimiter) Allow(ip netip.Addr) bool {
	var entry *RatelimiterEntry
	// lookup entry
	rate.mu.RLock()
	entry = rate.table[ip]
	rate.mu.RUnlock()

	// make new entry if not found
	if entry == nil {
		entry = new(RatelimiterEntry)
		entry.tokens = maxTokens - packetCost
		entry.lastTime = rate.timeNow()
		rate.mu.Lock()
		rate.table[ip] = entry
		if len(rate.table) == 1 {
			rate.stopReset <- struct{}{}
		}
		rate.mu.Unlock()
		return true
	}

	// add tokens to entry
	entry.mu.Lock()
	now := rate.timeNow()
	entry.tokens += now.Sub(entry.lastTime).Nanoseconds()
	entry.lastTime = now
	if entry.tokens > maxTokens {
		entry.tokens = maxTokens
	}

	// subtract cost of packet
	if entry.tokens > packetCost {
		entry.tokens -= packetCost
		entry.mu.Unlock()
		return true
	}
	entry.mu.Unlock()
	return false
}
