package main

import (
	"fmt"

	"github.com/spf13/cobra"
)

var editCmd = &cobra.Command{
	Use:   "edit <provider_name>",
	Short: "Display the absolute path to the managed configuration",
	Long:  `Display the absolute path to the managed configuration file or directory.`,
	Args:  cobra.ExactArgs(1),
	RunE:  runEdit,
}

func init() {
	rootCmd.AddCommand(editCmd)
}

func runEdit(cmd *cobra.Command, args []string) error {
	providerName := args[0]

	// Load providers config
	config, err := loadProviders()
	if err != nil {
		return fmt.Errorf("failed to load providers: %w", err)
	}

	// Check if provider exists
	provider, exists := config.Providers[providerName]
	if !exists {
		return fmt.Errorf("provider '%s' not found", providerName)
	}

	// Display the absolute path
	fmt.Println(provider.OriginalPath)
	
	// Display reminder
	fmt.Printf("\nReminder: After making changes, use 'llmctx add-version %s <new_version_name>' to save your changes.\n", providerName)

	return nil
}