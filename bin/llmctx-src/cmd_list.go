package main

import (
	"fmt"
	"os"
	"sort"

	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all managed providers and their versions",
	Long:  `List all managed providers and their versions.`,
	RunE:  runList,
}

func init() {
	rootCmd.AddCommand(listCmd)
}

func runList(cmd *cobra.Command, args []string) error {
	config, err := loadProviders()
	if err != nil {
		return fmt.Errorf("failed to load providers: %w", err)
	}

	if len(config.Providers) == 0 {
		fmt.Println("No providers configured.")
		return nil
	}

	// Sort provider names for consistent output
	var providerNames []string
	for name := range config.Providers {
		providerNames = append(providerNames, name)
	}
	sort.Strings(providerNames)

	for _, name := range providerNames {
		provider := config.Providers[name]
		fmt.Printf("Provider: %s\n", provider.Name)
		fmt.Printf("  Original Path: %s\n", provider.OriginalPath)
		fmt.Printf("  Type: %s\n", provider.Type)
		fmt.Printf("  Current Active Version: %s\n", provider.CurrentVersion)

		// List available versions
		versions, err := getAvailableVersions(provider.Name)
		if err != nil {
			fmt.Printf("  Available Versions: (error reading versions: %v)\n", err)
		} else if len(versions) == 0 {
			fmt.Printf("  Available Versions: (none)\n")
		} else {
			fmt.Printf("  Available Versions: %v\n", versions)
		}
		fmt.Println()
	}

	return nil
}

// getAvailableVersions returns a sorted list of available versions for a provider
func getAvailableVersions(providerName string) ([]string, error) {
	versionDir, err := getVersionDir(providerName)
	if err != nil {
		return nil, err
	}

	// Check if version directory exists
	if _, err := os.Stat(versionDir); os.IsNotExist(err) {
		return []string{}, nil
	}

	entries, err := os.ReadDir(versionDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read version directory: %w", err)
	}

	var versions []string
	for _, entry := range entries {
		if entry.IsDir() || entry.Type().IsRegular() {
			versions = append(versions, entry.Name())
		}
	}

	sort.Strings(versions)
	return versions, nil
}