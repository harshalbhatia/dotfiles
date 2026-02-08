package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestIntegrationWorkflow(t *testing.T) {
	// Create a temporary directory for testing
	tempDir, err := os.MkdirTemp("", "llmctx-integration-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Override home directory for testing
	originalHome := os.Getenv("HOME")
	os.Setenv("HOME", tempDir)
	defer os.Setenv("HOME", originalHome)

	// Build the binary
	buildCmd := exec.Command("go", "build", "-o", "llmctx-test", ".")
	buildCmd.Dir = "."
	if err := buildCmd.Run(); err != nil {
		t.Fatalf("Failed to build binary: %v", err)
	}
	defer os.Remove("llmctx-test")

	// Create a test configuration file
	testConfigDir := filepath.Join(tempDir, "test-config")
	if err := os.MkdirAll(testConfigDir, 0755); err != nil {
		t.Fatalf("Failed to create test config dir: %v", err)
	}

	testConfigFile := filepath.Join(testConfigDir, "config.yaml")
	initialContent := "version: 1\napi_key: initial_key\n"
	if err := os.WriteFile(testConfigFile, []byte(initialContent), 0644); err != nil {
		t.Fatalf("Failed to create test config file: %v", err)
	}

	// Test 1: List with no providers
	listCmd := exec.Command("./llmctx-test", "list")
	listCmd.Dir = "."
	output, err := listCmd.Output()
	if err != nil {
		t.Fatalf("List command failed: %v", err)
	}
	if !strings.Contains(string(output), "No providers configured") {
		t.Errorf("Expected 'No providers configured', got: %s", string(output))
	}

	// Test 2: Add provider (simulated - we can't test interactive input easily)
	// Instead, we'll test the underlying functionality directly
	config := &ProvidersConfig{
		Providers: make(map[string]Provider),
	}

	provider := Provider{
		Name:           "test-provider",
		OriginalPath:   testConfigFile,
		Type:           "file",
		CurrentVersion: "initial",
	}

	config.Providers["test-provider"] = provider
	if err := config.saveProviders(); err != nil {
		t.Fatalf("Failed to save provider config: %v", err)
	}

	// Create initial version
	versionPath, err := getVersionPath("test-provider", "initial")
	if err != nil {
		t.Fatalf("Failed to get version path: %v", err)
	}

	versionDir := filepath.Dir(versionPath)
	if err := os.MkdirAll(versionDir, 0755); err != nil {
		t.Fatalf("Failed to create version directory: %v", err)
	}

	if err := copyPath(testConfigFile, versionPath, "file"); err != nil {
		t.Fatalf("Failed to copy initial version: %v", err)
	}

	// Test 3: List with one provider
	listCmd = exec.Command("./llmctx-test", "list")
	listCmd.Dir = "."
	output, err = listCmd.Output()
	if err != nil {
		t.Fatalf("List command failed: %v", err)
	}
	outputStr := string(output)
	if !strings.Contains(outputStr, "test-provider") {
		t.Errorf("Expected provider name in output, got: %s", outputStr)
	}
	if !strings.Contains(outputStr, testConfigFile) {
		t.Errorf("Expected config file path in output, got: %s", outputStr)
	}
	if !strings.Contains(outputStr, "initial") {
		t.Errorf("Expected initial version in output, got: %s", outputStr)
	}

	// Test 4: Edit command
	editCmd := exec.Command("./llmctx-test", "edit", "test-provider")
	editCmd.Dir = "."
	output, err = editCmd.Output()
	if err != nil {
		t.Fatalf("Edit command failed: %v", err)
	}
	if !strings.Contains(string(output), testConfigFile) {
		t.Errorf("Expected config file path in edit output, got: %s", string(output))
	}

	// Test 5: Modify the config file and add a new version
	modifiedContent := "version: 2\napi_key: modified_key\n"
	if err := os.WriteFile(testConfigFile, []byte(modifiedContent), 0644); err != nil {
		t.Fatalf("Failed to modify config file: %v", err)
	}

	// Test add-version command
	addVersionCmd := exec.Command("./llmctx-test", "add-version", "test-provider", "v2")
	addVersionCmd.Dir = "."
	output, err = addVersionCmd.Output()
	if err != nil {
		t.Fatalf("Add-version command failed: %v", err)
	}
	if !strings.Contains(string(output), "Successfully saved") {
		t.Errorf("Expected success message in add-version output, got: %s", string(output))
	}

	// Test 6: Set version back to initial
	setVersionCmd := exec.Command("./llmctx-test", "set-version", "test-provider", "initial")
	setVersionCmd.Dir = "."
	output, err = setVersionCmd.Output()
	if err != nil {
		t.Fatalf("Set-version command failed: %v", err)
	}
	if !strings.Contains(string(output), "Successfully set") {
		t.Errorf("Expected success message in set-version output, got: %s", string(output))
	}

	// Verify the file content was restored
	restoredContent, err := os.ReadFile(testConfigFile)
	if err != nil {
		t.Fatalf("Failed to read restored config file: %v", err)
	}
	if string(restoredContent) != initialContent {
		t.Errorf("Content not restored correctly. Expected: %q, got: %q", initialContent, string(restoredContent))
	}

	// Test 7: Error cases
	// Test non-existent provider
	editCmd = exec.Command("./llmctx-test", "edit", "non-existent")
	editCmd.Dir = "."
	_, err = editCmd.Output()
	if err == nil {
		t.Error("Expected error for non-existent provider")
	}

	// Test non-existent version
	setVersionCmd = exec.Command("./llmctx-test", "set-version", "test-provider", "non-existent")
	setVersionCmd.Dir = "."
	_, err = setVersionCmd.Output()
	if err == nil {
		t.Error("Expected error for non-existent version")
	}
}