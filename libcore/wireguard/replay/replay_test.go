/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package replay

import (
	"testing"
)

/* Ported from the linux kernel implementation
 *
 *
 */

const RejectAfterMessages = 1<<64 - 1<<13 - 1

func TestReplay(t *testing.T) {
	var filter Filter

	const T_LIM = windowSize + 1

	testNumber := 0
	T := func(n uint64, expected bool) {
		testNumber++
		if filter.ValidateCounter(n, RejectAfterMessages) != expected {
			t.Fatal("Test", testNumber, "failed", n, expected)
		}
	}

	filter.Reset()

	T(0, true)                      /*  1 */
	T(1, true)                      /*  2 */
	T(1, false)                     /*  3 */
	T(9, true)                      /*  4 */
	T(8, true)                      /*  5 */
	T(7, true)                      /*  6 */
	T(7, false)                     /*  7 */
	T(T_LIM, true)                  /*  8 */
	T(T_LIM-1, true)                /*  9 */
	T(T_LIM-1, false)               /* 10 */
	T(T_LIM-2, true)                /* 11 */
	T(2, true)                      /* 12 */
	T(2, false)                     /* 13 */
	T(T_LIM+16, true)               /* 14 */
	T(3, false)                     /* 15 */
	T(T_LIM+16, false)              /* 16 */
	T(T_LIM*4, true)                /* 17 */
	T(T_LIM*4-(T_LIM-1), true)      /* 18 */
	T(10, false)                    /* 19 */
	T(T_LIM*4-T_LIM, false)         /* 20 */
	T(T_LIM*4-(T_LIM+1), false)     /* 21 */
	T(T_LIM*4-(T_LIM-2), true)      /* 22 */
	T(T_LIM*4+1-T_LIM, false)       /* 23 */
	T(0, false)                     /* 24 */
	T(RejectAfterMessages, false)   /* 25 */
	T(RejectAfterMessages-1, true)  /* 26 */
	T(RejectAfterMessages, false)   /* 27 */
	T(RejectAfterMessages-1, false) /* 28 */
	T(RejectAfterMessages-2, true)  /* 29 */
	T(RejectAfterMessages+1, false) /* 30 */
	T(RejectAfterMessages+2, false) /* 31 */
	T(RejectAfterMessages-2, false) /* 32 */
	T(RejectAfterMessages-3, true)  /* 33 */
	T(0, false)                     /* 34 */

	t.Log("Bulk test 1")
	filter.Reset()
	testNumber = 0
	for i := uint64(1); i <= windowSize; i++ {
		T(i, true)
	}
	T(0, true)
	T(0, false)

	t.Log("Bulk test 2")
	filter.Reset()
	testNumber = 0
	for i := uint64(2); i <= windowSize+1; i++ {
		T(i, true)
	}
	T(1, true)
	T(0, false)

	t.Log("Bulk test 3")
	filter.Reset()
	testNumber = 0
	for i := uint64(windowSize + 1); i > 0; i-- {
		T(i, true)
	}

	t.Log("Bulk test 4")
	filter.Reset()
	testNumber = 0
	for i := uint64(windowSize + 2); i > 1; i-- {
		T(i, true)
	}
	T(0, false)

	t.Log("Bulk test 5")
	filter.Reset()
	testNumber = 0
	for i := uint64(windowSize); i > 0; i-- {
		T(i, true)
	}
	T(windowSize+1, true)
	T(0, false)

	t.Log("Bulk test 6")
	filter.Reset()
	testNumber = 0
	for i := uint64(windowSize); i > 0; i-- {
		T(i, true)
	}
	T(0, true)
	T(windowSize+1, true)
}
