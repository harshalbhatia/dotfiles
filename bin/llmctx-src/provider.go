package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// Provider represents a managed configuration provider
type Provider struct {
	Name           string `json:"name"`
	OriginalPath   string `json:"original_path"`
	Type           string `json:"type"` // "file" or "directory"
	CurrentVersion string `json:"current_version"`
}

// ProvidersConfig holds all managed providers
type ProvidersConfig struct {
	Providers map[string]Provider `json:"providers"`
}

// getConfigDir returns the base configuration directory
func getConfigDir() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}
	return filepath.Join(homeDir, ".llmctx"), nil
}

// getProvidersFilePath returns the path to the providers.json file
func getProvidersFilePath() (string, error) {
	configDir, err := getConfigDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(configDir, "providers.json"), nil
}

// loadProviders loads the providers configuration from disk
func loadProviders() (*ProvidersConfig, error) {
	providersFile, err := getProvidersFilePath()
	if err != nil {
		return nil, err
	}

	// If file doesn't exist, return empty config
	if _, err := os.Stat(providersFile); os.IsNotExist(err) {
		return &ProvidersConfig{Providers: make(map[string]Provider)}, nil
	}

	data, err := os.ReadFile(providersFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read providers file: %w", err)
	}

	var config ProvidersConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("failed to parse providers file: %w", err)
	}

	if config.Providers == nil {
		config.Providers = make(map[string]Provider)
	}

	return &config, nil
}

// saveProviders saves the providers configuration to disk
func (pc *ProvidersConfig) saveProviders() error {
	configDir, err := getConfigDir()
	if err != nil {
		return err
	}

	// Ensure config directory exists
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	providersFile, err := getProvidersFilePath()
	if err != nil {
		return err
	}

	data, err := json.MarshalIndent(pc, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal providers config: %w", err)
	}

	if err := os.WriteFile(providersFile, data, 0644); err != nil {
		return fmt.Errorf("failed to write providers file: %w", err)
	}

	return nil
}

// expandPath expands ~ to home directory
func expandPath(path string) (string, error) {
	if strings.HasPrefix(path, "~/") {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("failed to get home directory: %w", err)
		}
		return filepath.Join(homeDir, path[2:]), nil
	}
	return path, nil
}

// getVersionDir returns the directory path for storing versions of a provider
func getVersionDir(providerName string) (string, error) {
	configDir, err := getConfigDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(configDir, "providers", providerName, "versions"), nil
}

// getVersionPath returns the full path for a specific version of a provider
func getVersionPath(providerName, versionName string) (string, error) {
	versionDir, err := getVersionDir(providerName)
	if err != nil {
		return "", err
	}
	return filepath.Join(versionDir, versionName), nil
}