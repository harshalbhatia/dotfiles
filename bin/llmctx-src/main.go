package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "llmctx",
	Short: "Manage different versions of CLI tool configuration files and directories",
	Long:  `llmctx is a tool to manage different versions of CLI tool authentication/configuration files or directories.`,
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}