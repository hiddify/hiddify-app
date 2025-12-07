package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/peterbourgon/ff/v4"
	"github.com/peterbourgon/ff/v4/ffhelp"
	"github.com/peterbourgon/ff/v4/ffjson"
)

const appName = "vwarp"

func main() {
	args := os.Args[1:]
	ctx, _ := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	rootCmd := newRootCmd()
	versionCmd(rootCmd)
	err := rootCmd.command.Parse(
		args,
		ff.WithConfigFileFlag("config"),
		ff.WithConfigFileParser(ffjson.Parse),
	)

	switch {
	case errors.Is(err, ff.ErrHelp):
		fmt.Fprintf(os.Stderr, "%s\n", ffhelp.Command(rootCmd.command))
		os.Exit(0)
	case err != nil:
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	if err := rootCmd.command.Run(ctx); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func fatal(l *slog.Logger, err error) {
	l.Error(err.Error())
	os.Exit(1)
}
