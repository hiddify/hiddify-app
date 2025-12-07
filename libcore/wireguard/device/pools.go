/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package device

import (
	"sync"
	"sync/atomic"
)

type WaitPool struct {
	pool  sync.Pool
	cond  sync.Cond
	lock  sync.Mutex
	count atomic.Uint32
	max   uint32
}

func NewWaitPool(max uint32, new func() any) *WaitPool {
	p := &WaitPool{pool: sync.Pool{New: new}, max: max}
	p.cond = sync.Cond{L: &p.lock}
	return p
}

func (p *WaitPool) Get() any {
	if p.max != 0 {
		p.lock.Lock()
		for p.count.Load() >= p.max {
			p.cond.Wait()
		}
		p.count.Add(1)
		p.lock.Unlock()
	}
	return p.pool.Get()
}

func (p *WaitPool) Put(x any) {
	p.pool.Put(x)
	if p.max == 0 {
		return
	}
	p.count.Add(^uint32(0))
	p.cond.Signal()
}

func (device *Device) PopulatePools() {
	device.pool.inboundElementsContainer = NewWaitPool(PreallocatedBuffersPerPool, func() any {
		s := make([]*QueueInboundElement, 0, device.BatchSize())
		return &QueueInboundElementsContainer{elems: s}
	})
	device.pool.outboundElementsContainer = NewWaitPool(PreallocatedBuffersPerPool, func() any {
		s := make([]*QueueOutboundElement, 0, device.BatchSize())
		return &QueueOutboundElementsContainer{elems: s}
	})
	device.pool.messageBuffers = NewWaitPool(PreallocatedBuffersPerPool, func() any {
		return new([MaxMessageSize]byte)
	})
	device.pool.inboundElements = NewWaitPool(PreallocatedBuffersPerPool, func() any {
		return new(QueueInboundElement)
	})
	device.pool.outboundElements = NewWaitPool(PreallocatedBuffersPerPool, func() any {
		return new(QueueOutboundElement)
	})
}

func (device *Device) GetInboundElementsContainer() *QueueInboundElementsContainer {
	c := device.pool.inboundElementsContainer.Get().(*QueueInboundElementsContainer)
	c.Mutex = sync.Mutex{}
	return c
}

func (device *Device) PutInboundElementsContainer(c *QueueInboundElementsContainer) {
	for i := range c.elems {
		c.elems[i] = nil
	}
	c.elems = c.elems[:0]
	device.pool.inboundElementsContainer.Put(c)
}

func (device *Device) GetOutboundElementsContainer() *QueueOutboundElementsContainer {
	c := device.pool.outboundElementsContainer.Get().(*QueueOutboundElementsContainer)
	c.Mutex = sync.Mutex{}
	return c
}

func (device *Device) PutOutboundElementsContainer(c *QueueOutboundElementsContainer) {
	for i := range c.elems {
		c.elems[i] = nil
	}
	c.elems = c.elems[:0]
	device.pool.outboundElementsContainer.Put(c)
}

func (device *Device) GetMessageBuffer() *[MaxMessageSize]byte {
	return device.pool.messageBuffers.Get().(*[MaxMessageSize]byte)
}

func (device *Device) PutMessageBuffer(msg *[MaxMessageSize]byte) {
	device.pool.messageBuffers.Put(msg)
}

func (device *Device) GetInboundElement() *QueueInboundElement {
	return device.pool.inboundElements.Get().(*QueueInboundElement)
}

func (device *Device) PutInboundElement(elem *QueueInboundElement) {
	elem.clearPointers()
	device.pool.inboundElements.Put(elem)
}

func (device *Device) GetOutboundElement() *QueueOutboundElement {
	return device.pool.outboundElements.Get().(*QueueOutboundElement)
}

func (device *Device) PutOutboundElement(elem *QueueOutboundElement) {
	elem.clearPointers()
	device.pool.outboundElements.Put(elem)
}
