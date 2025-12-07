/* SPDX-License-Identifier: MIT
 *
 * Copyright (C) 2017-2023 WireGuard LLC. All Rights Reserved.
 */

package device

import (
	"fmt"
	"log"
	"log/slog"
	"os"
)

// A Logger provides logging for a Device.
// The functions are Printf-style functions.
// They must be safe for concurrent use.
// They do not require a trailing newline in the format.
// If nil, that level of logging will be silent.
type Logger struct {
	Verbosef func(format string, args ...any)
	Errorf   func(format string, args ...any)
}

// Log levels for use with NewLogger.
const (
	LogLevelSilent = iota
	LogLevelError
	LogLevelVerbose
)

// Function for use in Logger for discarding logged lines.
func DiscardLogf(format string, args ...any) {}

// NewLogger constructs a Logger that writes to stdout.
// It logs at the specified log level and above.
// It decorates log lines with the log level, date, time, and prepend.
func NewLogger(level int, prepend string) *Logger {
	logger := &Logger{DiscardLogf, DiscardLogf}
	logf := func(prefix string) func(string, ...any) {
		return log.New(os.Stdout, prefix+": "+prepend, log.Ldate|log.Ltime).Printf
	}
	if level >= LogLevelVerbose {
		logger.Verbosef = logf("DEBUG")
	}
	if level >= LogLevelError {
		logger.Errorf = logf("ERROR")
	}
	return logger
}

func NewSLogger(l *slog.Logger) *Logger {
	return &Logger{
		Verbosef: func(format string, v ...any) {
			l.Debug(fmt.Sprintf(format, v...))
		},
		Errorf: func(format string, v ...any) {
			l.Error(fmt.Sprintf(format, v...))
		},
	}
}
