package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var addVersionCmd = &cobra.Command{
	Use:   "add-version <provider_name> <version_name>",
	Short: "Save the current state of a managed configuration as a new version",
	Long:  `Save the current state of a managed configuration file or directory as a new named version.`,
	Args:  cobra.ExactArgs(2),
	RunE:  runAddVersion,
}

func init() {
	rootCmd.AddCommand(addVersionCmd)
}

func runAddVersion(cmd *cobra.Command, args []string) error {
	providerName := args[0]
	versionName := args[1]

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

	// Check if original path still exists
	if _, err := os.Stat(provider.OriginalPath); os.IsNotExist(err) {
		return fmt.Errorf("original path '%s' no longer exists", provider.OriginalPath)
	}

	// Get version path
	versionPath, err := getVersionPath(providerName, versionName)
	if err != nil {
		return fmt.Errorf("failed to get version path: %w", err)
	}

	// If version already exists, remove it first (for directories)
	if _, err := os.Stat(versionPath); err == nil {
		if provider.Type == "directory" {
			if err := os.RemoveAll(versionPath); err != nil {
				return fmt.Errorf("failed to remove existing version: %w", err)
			}
		} else {
			if err := os.Remove(versionPath); err != nil {
				return fmt.Errorf("failed to remove existing version: %w", err)
			}
		}
	}

	// Ensure version directory exists
	versionDir, err := getVersionDir(providerName)
	if err != nil {
		return fmt.Errorf("failed to get version directory: %w", err)
	}
	if err := os.MkdirAll(versionDir, 0755); err != nil {
		return fmt.Errorf("failed to create version directory: %w", err)
	}

	// Copy current state to version storage
	if err := copyPath(provider.OriginalPath, versionPath, provider.Type); err != nil {
		return fmt.Errorf("failed to copy current state to version storage: %w", err)
	}

	fmt.Printf("Successfully saved current state of '%s' as version '%s'\n", providerName, versionName)
	return nil
}