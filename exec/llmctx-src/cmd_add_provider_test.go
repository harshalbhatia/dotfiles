package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCopyPath(t *testing.T) {
	// Create a temporary directory for testing
	tempDir, err := os.MkdirTemp("", "llmctx-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	t.Run("copy file", func(t *testing.T) {
		// Create a test file
		srcFile := filepath.Join(tempDir, "test.txt")
		content := "test content"
		if err := os.WriteFile(srcFile, []byte(content), 0644); err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}

		// Copy the file
		dstFile := filepath.Join(tempDir, "test_copy.txt")
		if err := copyPath(srcFile, dstFile, "file"); err != nil {
			t.Fatalf("copyPath failed: %v", err)
		}

		// Verify the copy
		copiedContent, err := os.ReadFile(dstFile)
		if err != nil {
			t.Fatalf("Failed to read copied file: %v", err)
		}

		if string(copiedContent) != content {
			t.Errorf("Content mismatch: got %q, want %q", string(copiedContent), content)
		}
	})

	t.Run("copy directory", func(t *testing.T) {
		// Create a test directory with a file
		srcDir := filepath.Join(tempDir, "testdir")
		if err := os.MkdirAll(srcDir, 0755); err != nil {
			t.Fatalf("Failed to create test directory: %v", err)
		}

		testFile := filepath.Join(srcDir, "file.txt")
		content := "directory test content"
		if err := os.WriteFile(testFile, []byte(content), 0644); err != nil {
			t.Fatalf("Failed to create test file in directory: %v", err)
		}

		// Copy the directory
		dstDir := filepath.Join(tempDir, "testdir_copy")
		if err := copyPath(srcDir, dstDir, "directory"); err != nil {
			t.Fatalf("copyPath failed: %v", err)
		}

		// Verify the copy
		copiedFile := filepath.Join(dstDir, "file.txt")
		copiedContent, err := os.ReadFile(copiedFile)
		if err != nil {
			t.Fatalf("Failed to read copied file: %v", err)
		}

		if string(copiedContent) != content {
			t.Errorf("Content mismatch: got %q, want %q", string(copiedContent), content)
		}
	})
}

func TestAddProviderValidation(t *testing.T) {
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

	// Test that we can detect file vs directory correctly
	testFile := filepath.Join(tempDir, "test.txt")
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	testDir := filepath.Join(tempDir, "testdir")
	if err := os.MkdirAll(testDir, 0755); err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}

	// Test file detection
	fileInfo, err := os.Stat(testFile)
	if err != nil {
		t.Fatalf("Failed to stat test file: %v", err)
	}
	if fileInfo.IsDir() {
		t.Error("Test file should not be detected as directory")
	}

	// Test directory detection
	dirInfo, err := os.Stat(testDir)
	if err != nil {
		t.Fatalf("Failed to stat test directory: %v", err)
	}
	if !dirInfo.IsDir() {
		t.Error("Test directory should be detected as directory")
	}
}