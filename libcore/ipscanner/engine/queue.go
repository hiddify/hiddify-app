package engine

import (
	"github.com/bepass-org/vwarp/ipscanner/statute"
	"log/slog"
	"sort"
	"sync"
)

type IPQueue struct {
	queue        []statute.IPInfo
	maxQueueSize int
	mu           sync.Mutex
	log          *slog.Logger
}

func NewIPQueue(opts *statute.ScannerOptions) *IPQueue {
	return &IPQueue{
		queue:        make([]statute.IPInfo, 0),
		maxQueueSize: opts.IPQueueSize,
		log:          opts.Logger,
	}
}

func (q *IPQueue) Enqueue(info statute.IPInfo) bool {
	q.mu.Lock()
	defer q.mu.Unlock()

	// Insert the new item in sorted position.
	index := sort.Search(len(q.queue), func(i int) bool { return q.queue[i].RTT > info.RTT })
	q.queue = append(q.queue, statute.IPInfo{})
	copy(q.queue[index+1:], q.queue[index:])
	q.queue[index] = info

	// If the queue is larger than the max size, trim the worst item.
	if q.maxQueueSize > 0 && len(q.queue) > q.maxQueueSize {
		q.queue = q.queue[:len(q.queue)-1]
	}

	return false
}

func (q *IPQueue) AvailableIPs(desc bool) []statute.IPInfo {
	q.mu.Lock()
	defer q.mu.Unlock()

	// Create a separate slice to avoid returning a pointer to the internal state.
	sortedQueue := make([]statute.IPInfo, len(q.queue))
	copy(sortedQueue, q.queue)

	// The queue is already sorted ascendingly. Only sort if descending is requested.
	if desc {
		sort.Slice(sortedQueue, func(i, j int) bool {
			return sortedQueue[i].RTT > sortedQueue[j].RTT
		})
	}

	return sortedQueue
}

func (q *IPQueue) Size() int {
	q.mu.Lock()
	defer q.mu.Unlock()
	return len(q.queue)
}
