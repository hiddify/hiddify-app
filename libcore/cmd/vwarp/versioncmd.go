package main

import (
	"context"
	"fmt"
	"os"

	"github.com/carlmjohnson/versioninfo"
	"github.com/peterbourgon/ff/v4"
)

var version string = ""

func versionCmd(rootConfig *rootConfig) {
	command := &ff.Command{
		Name:      "version",
		ShortHelp: "displays version",
		Exec: func(ctx context.Context, args []string) error {
			if version == "" {
				version = versioninfo.Short()
			}
			fmt.Fprintf(os.Stderr, "%s\n", version)
			return nil
		},
	}
	rootConfig.command.Subcommands = append(rootConfig.command.Subcommands, command)
}
