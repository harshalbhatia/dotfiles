package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

var addProviderCmd = &cobra.Command{
	Use:   "add-provider",
	Short: "Register a new configuration file or directory to be managed",
	Long:  `Register a new configuration file or directory to be managed by llmctx.`,
	RunE:  runAddProvider,
}

func init() {
	rootCmd.AddCommand(addProviderCmd)
}

func runAddProvider(cmd *cobra.Command, args []string) error {
	reader := bufio.NewReader(os.Stdin)

	// Get provider name
	fmt.Print("Enter a name for the provider: ")
	providerName, err := reader.ReadString('\n')
	if err != nil {
		return fmt.Errorf("failed to read provider name: %w", err)
	}
	providerName = strings.TrimSpace(providerName)
	if providerName == "" {
		return fmt.Errorf("provider name cannot be empty")
	}

	// Check if provider already exists
	config, err := loadProviders()
	if err != nil {
		return fmt.Errorf("failed to load providers: %w", err)
	}

	if _, exists := config.Providers[providerName]; exists {
		return fmt.Errorf("provider '%s' already exists", providerName)
	}

	// Get original path
	fmt.Print("Enter the absolute path to the configuration file or directory to manage: ")
	originalPath, err := reader.ReadString('\n')
	if err != nil {
		return fmt.Errorf("failed to read original path: %w", err)
	}
	originalPath = strings.TrimSpace(originalPath)
	if originalPath == "" {
		return fmt.Errorf("original path cannot be empty")
	}

	// Expand ~ in path
	expandedPath, err := expandPath(originalPath)
	if err != nil {
		return fmt.Errorf("failed to expand path: %w", err)
	}

	// Check if path exists
	if _, err := os.Stat(expandedPath); os.IsNotExist(err) {
		return fmt.Errorf("Path '%s' does not exist. First create the file and then import it!", expandedPath)
	}

	// Determine type (file or directory)
	fileInfo, err := os.Stat(expandedPath)
	if err != nil {
		return fmt.Errorf("failed to stat path: %w", err)
	}

	pathType := "file"
	if fileInfo.IsDir() {
		pathType = "directory"
	}

	// Get initial version name
	fmt.Print("Enter a name for the initial version: ")
	initialVersion, err := reader.ReadString('\n')
	if err != nil {
		return fmt.Errorf("failed to read initial version: %w", err)
	}
	initialVersion = strings.TrimSpace(initialVersion)
	if initialVersion == "" {
		return fmt.Errorf("initial version name cannot be empty")
	}

	// Create version directory
	versionPath, err := getVersionPath(providerName, initialVersion)
	if err != nil {
		return fmt.Errorf("failed to get version path: %w", err)
	}

	versionDir := filepath.Dir(versionPath)
	if err := os.MkdirAll(versionDir, 0755); err != nil {
		return fmt.Errorf("failed to create version directory: %w", err)
	}

	// Copy the original file/directory to version storage
	if err := copyPath(expandedPath, versionPath, pathType); err != nil {
		return fmt.Errorf("failed to copy original path to version storage: %w", err)
	}

	// Add provider to config
	provider := Provider{
		Name:           providerName,
		OriginalPath:   expandedPath,
		Type:           pathType,
		CurrentVersion: initialVersion,
	}

	config.Providers[providerName] = provider

	// Save config
	if err := config.saveProviders(); err != nil {
		return fmt.Errorf("failed to save providers config: %w", err)
	}

	fmt.Printf("Successfully added provider '%s' with initial version '%s'\n", providerName, initialVersion)
	return nil
}

// copyPath copies a file or directory from src to dst
func copyPath(src, dst, pathType string) error {
	if pathType == "directory" {
		cmd := exec.Command("cp", "-r", src, dst)
		return cmd.Run()
	} else {
		cmd := exec.Command("cp", src, dst)
		return cmd.Run()
	}
}