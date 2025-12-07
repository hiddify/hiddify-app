package engine

import (
	"context"
	"errors"
	"log/slog"
	"net/netip"
	"sync"

	"github.com/bepass-org/vwarp/ipscanner/iterator"
	"github.com/bepass-org/vwarp/ipscanner/ping"
	"github.com/bepass-org/vwarp/ipscanner/statute"
)

type Engine struct {
	ipQueue *IPQueue
	log     *slog.Logger
	opts    *statute.ScannerOptions
}

func NewScannerEngine(opts *statute.ScannerOptions) *Engine {
	queue := NewIPQueue(opts)

	return &Engine{
		ipQueue: queue,
		log:     opts.Logger,
		opts:    opts,
	}
}

func (e *Engine) GetAvailableIPs(desc bool) []statute.IPInfo {
	if e.ipQueue != nil {
		return e.ipQueue.AvailableIPs(desc)
	}
	return nil
}

func (e *Engine) runPortScan(ctx context.Context, cancel context.CancelFunc) {
	e.log.Info("Starting dedicated port scan.")
	var wg sync.WaitGroup

	for ip, ports := range e.opts.TestPortsForIPs {
		ipCopy, portsCopy := ip, ports
		for _, port := range portsCopy {
			if ctx.Err() != nil {
				break
			}
			wg.Add(1)
			go func(ip netip.Addr, port uint16) {
				defer wg.Done()
				if ctx.Err() != nil {
					return
				}

				tempOpts := *e.opts
				tempOpts.Port = port
				pinger := ping.Ping{Options: &tempOpts}

				addrWithPort := netip.AddrPortFrom(ip, port)
				e.log.Debug("Testing port", "endpoint", addrWithPort)
				warpInfo, err := pinger.WarpPing(ctx, ip)
				if err == nil {
					e.log.Debug("WARP port scan success", "addr", warpInfo.AddrPort, "rtt", warpInfo.RTT)
					e.ipQueue.Enqueue(warpInfo)
				} else if !errors.Is(err, context.Canceled) && !errors.Is(err, context.DeadlineExceeded) {
					e.log.Debug("WARP port scan failed", "addr", addrWithPort, "error", err)
				}
			}(ipCopy, port)
		}
	}
	wg.Wait()
	e.log.Info("Port scan finished.", "found_count", e.ipQueue.Size())
}

// Run executes the multi-stage strategic scan using a streaming pipeline.
func (e *Engine) Run(parentCtx context.Context) {
	ctx, cancel := context.WithCancel(parentCtx)
	defer cancel()

	// Check for dedicated port scan mode first.
	if len(e.opts.TestPortsForIPs) > 0 {
		e.runPortScan(ctx, cancel)
		return // Exit after port scan is complete.
	}

	e.log.Debug("[1] Generating candidate IPs and endpoints")

	candidatePorts := make(map[netip.Addr][]uint16)

	appendIfMissing := func(slice []uint16, v uint16) []uint16 {
		for _, x := range slice {
			if x == v {
				return slice
			}
		}
		return append(slice, v)
	}

	generator := iterator.NewIterator(e.opts)
	cidrIPs, err := generator.Generate()
	if err != nil {
		e.log.Debug("Could not generate IPs from CIDR ranges", "reason", err)
	} else {
		for _, ip := range cidrIPs {
			candidatePorts[ip] = appendIfMissing(candidatePorts[ip], 0)
		}
	}

	for _, ep := range e.opts.CustomEndpoints {
		ip := ep.Addr()
		port := ep.Port()
		candidatePorts[ip] = appendIfMissing(candidatePorts[ip], port)
	}

	allCandidateIPInfos := make([]statute.IPInfo, 0)
	for ip, ports := range candidatePorts {
		if len(ports) == 0 {
			allCandidateIPInfos = append(allCandidateIPInfos, statute.IPInfo{AddrPort: netip.AddrPortFrom(ip, 0)})
			continue
		}
		for _, p := range ports {
			allCandidateIPInfos = append(allCandidateIPInfos, statute.IPInfo{AddrPort: netip.AddrPortFrom(ip, p)})
		}
	}
	e.log.Info("IP generation complete", "count", len(allCandidateIPInfos))
	if len(allCandidateIPInfos) == 0 {
		e.log.Warn("No candidate IPs were generated or provided, stopping scan.")
		return
	}

	var masterWg sync.WaitGroup
	concurrency := e.opts.ConcurrentScanners

	// Pipeline stages: generation -> ICMP -> TCP -> WARP
	// IP generation: push candidate AddrPort entries into the first channel.
	ipStream := make(chan statute.IPInfo, concurrency)
	masterWg.Add(1)
	go func() {
		defer masterWg.Done()
		defer close(ipStream) // Close the channel when generation is done
		for _, ipinfo := range allCandidateIPInfos {
			select {
			case ipStream <- ipinfo:
			case <-ctx.Done():
				return
			}
		}
	}()

	// ICMP Ping Filter
	icmpStream := make(chan statute.IPInfo, concurrency)
	if e.opts.IcmpPing {
		e.log.Debug("[INFO] Filtering IPs with ICMP Ping")
		pinger := ping.Ping{Options: e.opts}
		runFilterStage(ctx, &masterWg, concurrency, ipStream, icmpStream, func(ipinfo statute.IPInfo) (statute.IPInfo, bool) {
			info, err := pinger.IcmpPing(ctx, ipinfo.AddrPort.Addr())
			if err == nil && info.RTT <= e.opts.ICMPPingFilterRTT {
				info.AddrPort = netip.AddrPortFrom(ipinfo.AddrPort.Addr(), ipinfo.AddrPort.Port())
				e.log.Debug("ICMP ping success", "addr", info.AddrPort, "rtt", info.RTT)
				return info, true
			} else if err != nil && !errors.Is(err, context.Canceled) && !errors.Is(err, context.DeadlineExceeded) {
				e.log.Debug("ICMP ping failed", "addr", ipinfo.AddrPort, "error", err)
			}
			return statute.IPInfo{}, false
		})
	} else {
		// Bypass ICMP stage: pass items through.
		masterWg.Add(1)
		go func() {
			defer masterWg.Done()
			defer close(icmpStream)
			for ip := range ipStream {
				select {
				case icmpStream <- ip:
				case <-ctx.Done():
					return
				}
			}
		}()
	}

	// TCP Ping Filter
	tcpStream := make(chan statute.IPInfo, concurrency)
	if e.opts.TcpPing {
		e.log.Debug("[INFO] Filtering IPs with TCP Ping")
		runFilterStage(ctx, &masterWg, concurrency, icmpStream, tcpStream, func(ipinfo statute.IPInfo) (statute.IPInfo, bool) {
			// Use configured TCPPingPort for TCP probes; preserve the candidate AddrPort
			// for downstream WARP checks.
			localOpts := *e.opts
			localOpts.Port = e.opts.TCPPingPort
			pinger := ping.Ping{Options: &localOpts}
			info, err := pinger.TcpPing(ctx, ipinfo.AddrPort.Addr())
			if err == nil && info.RTT <= e.opts.TCPPingFilterRTT {
				// Preserve the original candidate AddrPort for downstream stages.
				info.AddrPort = ipinfo.AddrPort
				candidatePort := ipinfo.AddrPort.Port()
				e.log.Debug("TCP ping success", "tested_port", localOpts.Port, "candidate_port", candidatePort, "addr", info.AddrPort, "rtt", info.RTT)
				return info, true
			} else if err != nil && !errors.Is(err, context.Canceled) && !errors.Is(err, context.DeadlineExceeded) {
				e.log.Debug("TCP ping failed", "addr", ipinfo.AddrPort, "error", err)
			}
			return statute.IPInfo{}, false
		})
	} else {
		// Bypass TCP stage: pass items through.
		masterWg.Add(1)
		go func() {
			defer masterWg.Done()
			defer close(tcpStream)
			for ipinfo := range icmpStream {
				select {
				case tcpStream <- ipinfo:
				case <-ctx.Done():
					return
				}
			}
		}()
	}

	// WARP Ping (always run)
	e.log.Debug("[INFO] Finding valid endpoints with WARP Ping")
	masterWg.Add(1)
	go func() {
		defer masterWg.Done()
		var stageWg sync.WaitGroup
		for i := 0; i < concurrency; i++ {
			stageWg.Add(1)
			go func() {
				defer stageWg.Done()
				for ipInfo := range tcpStream {
					select {
					case <-ctx.Done():
						return
					default:
						// For each candidate, respect any provided port; if none was provided (0), let
						// the WarpPing implementation choose (it will pick a random WARP port if opts.Port==0).
						localOpts := *e.opts
						if ipInfo.AddrPort.Port() != 0 {
							localOpts.Port = ipInfo.AddrPort.Port()
						} else {
							localOpts.Port = e.opts.Port
						}
						pinger := ping.Ping{Options: &localOpts}
						warpInfo, err := pinger.WarpPing(ctx, ipInfo.AddrPort.Addr())
						if err == nil {
							e.log.Debug("WARP ping success", "addr", warpInfo.AddrPort, "rtt", warpInfo.RTT)
							e.ipQueue.Enqueue(warpInfo)

							if e.opts.StopOnFirstGoodIPs > 0 && e.ipQueue.Size() >= e.opts.StopOnFirstGoodIPs {
								e.log.Info("Target IP count reached, stopping scan.", "count", e.ipQueue.Size())
								cancel()
							}
						} else if !errors.Is(err, context.Canceled) && !errors.Is(err, context.DeadlineExceeded) {
							e.log.Debug("WARP ping failed", "addr", ipInfo.AddrPort.Addr(), "error", err)
						}
					}
				}
			}()
		}
		stageWg.Wait()
	}()

	// Wait for all stages to complete.
	masterWg.Wait()
	e.log.Info("Scan pipeline complete.", "found_count", e.ipQueue.Size())
}

// runFilterStage a generic helper function for creating a pipeline filter stage
// It creates a pool of workers that read from inChan, process items using filterFunc,
// and write successful results to outChan.
func runFilterStage[T_in any, T_out any](ctx context.Context, masterWg *sync.WaitGroup, concurrency int, inChan <-chan T_in, outChan chan<- T_out, filterFunc func(T_in) (T_out, bool)) {
	masterWg.Add(1)
	go func() {
		defer masterWg.Done()
		defer close(outChan) // Close the output channel when all workers in this stage are done

		var stageWg sync.WaitGroup
		for i := 0; i < concurrency; i++ {
			stageWg.Add(1)
			go func() {
				defer stageWg.Done()
				for item := range inChan {
					if ctx.Err() != nil { // Early exit if context is cancelled
						return
					}
					if result, ok := filterFunc(item); ok {
						select {
						case outChan <- result:
						case <-ctx.Done():
							return
						}
					}
				}
			}()
		}
		stageWg.Wait() // Wait for all workers in this stage to finish before closing the outChan
	}()
}
