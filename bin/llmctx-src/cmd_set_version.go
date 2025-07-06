package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/spf13/cobra"
)

var setVersionCmd = &cobra.Command{
	Use:   "set-version <provider_name> <version_name>",
	Short: "Replace the active configuration with a chosen version",
	Long:  `Replace the active configuration file or directory at its original location with a chosen version from storage.`,
	Args:  cobra.ExactArgs(2),
	RunE:  runSetVersion,
}

var forceFlag bool

func init() {
	setVersionCmd.Flags().BoolVar(&forceFlag, "force", false, "Force the operation even if current state is not backed up")
	rootCmd.AddCommand(setVersionCmd)
}

func runSetVersion(cmd *cobra.Command, args []string) error {
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

	// Check if target version exists
	targetVersionPath, err := getVersionPath(providerName, versionName)
	if err != nil {
		return fmt.Errorf("failed to get version path: %w", err)
	}

	if _, err := os.Stat(targetVersionPath); os.IsNotExist(err) {
		return fmt.Errorf("version '%s' not found for provider '%s'", versionName, providerName)
	}

	// Check if original path exists
	if _, err := os.Stat(provider.OriginalPath); os.IsNotExist(err) {
		return fmt.Errorf("original path '%s' no longer exists", provider.OriginalPath)
	}

	// Check if current state is backed up (unless force flag is used)
	if !forceFlag {
		isBackedUp, err := isCurrentStateBackedUp(provider)
		if err != nil {
			return fmt.Errorf("failed to check if current state is backed up: %w", err)
		}

		if !isBackedUp {
			return fmt.Errorf("current state of '%s' is not backed up in any version. Use 'llmctx add-version %s <version_name>' to back it up first, or use --force to proceed anyway", provider.OriginalPath, providerName)
		}
	}

	// Remove existing content at original path
	if provider.Type == "directory" {
		if err := os.RemoveAll(provider.OriginalPath); err != nil {
			return fmt.Errorf("failed to remove existing directory: %w", err)
		}
	} else {
		if err := os.Remove(provider.OriginalPath); err != nil {
			return fmt.Errorf("failed to remove existing file: %w", err)
		}
	}

	// Ensure parent directories exist
	parentDir := filepath.Dir(provider.OriginalPath)
	if err := os.MkdirAll(parentDir, 0755); err != nil {
		return fmt.Errorf("failed to create parent directories: %w", err)
	}

	// Copy version to original location
	if err := copyPath(targetVersionPath, provider.OriginalPath, provider.Type); err != nil {
		return fmt.Errorf("failed to copy version to original location: %w", err)
	}

	// Update current version in config
	provider.CurrentVersion = versionName
	config.Providers[providerName] = provider

	// Save config
	if err := config.saveProviders(); err != nil {
		return fmt.Errorf("failed to save providers config: %w", err)
	}

	fmt.Printf("Successfully set '%s' to version '%s'\n", providerName, versionName)
	return nil
}

// isCurrentStateBackedUp checks if the current state matches any existing version
func isCurrentStateBackedUp(provider Provider) (bool, error) {
	versions, err := getAvailableVersions(provider.Name)
	if err != nil {
		return false, err
	}

	for _, version := range versions {
		versionPath, err := getVersionPath(provider.Name, version)
		if err != nil {
			continue
		}

		// Compare current state with this version
		matches, err := comparePathContents(provider.OriginalPath, versionPath, provider.Type)
		if err != nil {
			continue
		}

		if matches {
			return true, nil
		}
	}

	return false, nil
}

// comparePathContents compares the contents of two paths (files or directories)
func comparePathContents(path1, path2, pathType string) (bool, error) {
	if pathType == "directory" {
		// Use diff -r to compare directories
		cmd := exec.Command("diff", "-r", path1, path2)
		err := cmd.Run()
		if err == nil {
			return true, nil // No differences found
		}
		// diff returns non-zero exit code when differences are found
		return false, nil
	} else {
		// Use diff to compare files
		cmd := exec.Command("diff", path1, path2)
		err := cmd.Run()
		if err == nil {
			return true, nil // No differences found
		}
		// diff returns non-zero exit code when differences are found
		return false, nil
	}
}