package main

import (
	"github.com/bepass-org/vwarp/proxy/pkg/mixed"
)

func main() {
	proxy := mixed.NewProxy()
	_ = proxy.ListenAndServe()
}
