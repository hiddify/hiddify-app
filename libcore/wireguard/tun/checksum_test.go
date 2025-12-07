package tun

import (
	"fmt"
	"math/rand"
	"testing"
)

func BenchmarkChecksum(b *testing.B) {
	lengths := []int{
		64,
		128,
		256,
		512,
		1024,
		1500,
		2048,
		4096,
		8192,
		9000,
		9001,
	}

	for _, length := range lengths {
		b.Run(fmt.Sprintf("%d", length), func(b *testing.B) {
			buf := make([]byte, length)
			rng := rand.New(rand.NewSource(1))
			rng.Read(buf)
			b.ResetTimer()
			for i := 0; i < b.N; i++ {
				checksum(buf, 0)
			}
		})
	}
}
