package main

import (
	"context"

	"github.com/bepass-org/vwarp/ipscanner"
)

func main() {
	// new scanner
	scanner := ipscanner.NewScanner(
		// ipscanner.WithHTTPPing(),
		ipscanner.WithUseIPv6(true),
	)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go scanner.Run(ctx)

	<-ctx.Done()
}
