package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestExpandPath(t *testing.T) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		t.Fatalf("Failed to get home directory: %v", err)
	}

	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "expand tilde path",
			input:    "~/test/path",
			expected: filepath.Join(homeDir, "test/path"),
		},
		{
			name:     "absolute path unchanged",
			input:    "/absolute/path",
			expected: "/absolute/path",
		},
		{
			name:     "relative path unchanged",
			input:    "relative/path",
			expected: "relative/path",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := expandPath(tt.input)
			if err != nil {
				t.Fatalf("expandPath failed: %v", err)
			}
			if result != tt.expected {
				t.Errorf("expandPath(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestLoadProvidersEmptyConfig(t *testing.T) {
	// Create a temporary directory for testing
	tempDir, err := os.MkdirTemp("", "llmctx-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Override home directory for testing
	originalHome := os.Getenv("HOME")
	os.Setenv("HOME", tempDir)
	defer os.Setenv("HOME", originalHome)

	config, err := loadProviders()
	if err != nil {
		t.Fatalf("loadProviders failed: %v", err)
	}

	if config.Providers == nil {
		t.Error("Providers map should not be nil")
	}

	if len(config.Providers) != 0 {
		t.Errorf("Expected empty providers map, got %d providers", len(config.Providers))
	}
}

func TestSaveAndLoadProviders(t *testing.T) {
	// Create a temporary directory for testing
	tempDir, err := os.MkdirTemp("", "llmctx-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Override home directory for testing
	originalHome := os.Getenv("HOME")
	os.Setenv("HOME", tempDir)
	defer os.Setenv("HOME", originalHome)

	// Create test provider config
	testProvider := Provider{
		Name:           "test-provider",
		OriginalPath:   "/test/path",
		Type:           "file",
		CurrentVersion: "v1",
	}

	config := &ProvidersConfig{
		Providers: map[string]Provider{
			"test-provider": testProvider,
		},
	}

	// Save the config
	err = config.saveProviders()
	if err != nil {
		t.Fatalf("saveProviders failed: %v", err)
	}

	// Load the config back
	loadedConfig, err := loadProviders()
	if err != nil {
		t.Fatalf("loadProviders failed: %v", err)
	}

	// Verify the loaded config
	if len(loadedConfig.Providers) != 1 {
		t.Errorf("Expected 1 provider, got %d", len(loadedConfig.Providers))
	}

	loadedProvider, exists := loadedConfig.Providers["test-provider"]
	if !exists {
		t.Error("test-provider not found in loaded config")
	}

	if loadedProvider.Name != testProvider.Name {
		t.Errorf("Name mismatch: got %q, want %q", loadedProvider.Name, testProvider.Name)
	}

	if loadedProvider.OriginalPath != testProvider.OriginalPath {
		t.Errorf("OriginalPath mismatch: got %q, want %q", loadedProvider.OriginalPath, testProvider.OriginalPath)
	}

	if loadedProvider.Type != testProvider.Type {
		t.Errorf("Type mismatch: got %q, want %q", loadedProvider.Type, testProvider.Type)
	}

	if loadedProvider.CurrentVersion != testProvider.CurrentVersion {
		t.Errorf("CurrentVersion mismatch: got %q, want %q", loadedProvider.CurrentVersion, testProvider.CurrentVersion)
	}
}

func TestGetConfigDir(t *testing.T) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		t.Fatalf("Failed to get home directory: %v", err)
	}

	configDir, err := getConfigDir()
	if err != nil {
		t.Fatalf("getConfigDir failed: %v", err)
	}

	expected := filepath.Join(homeDir, ".llmctx")
	if configDir != expected {
		t.Errorf("getConfigDir() = %q, want %q", configDir, expected)
	}
}

func TestGetVersionPath(t *testing.T) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		t.Fatalf("Failed to get home directory: %v", err)
	}

	versionPath, err := getVersionPath("test-provider", "v1")
	if err != nil {
		t.Fatalf("getVersionPath failed: %v", err)
	}

	expected := filepath.Join(homeDir, ".llmctx", "providers", "test-provider", "versions", "v1")
	if versionPath != expected {
		t.Errorf("getVersionPath() = %q, want %q", versionPath, expected)
	}
}