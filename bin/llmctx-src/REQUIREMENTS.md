## `llmctx` Tool Requirements Specification

### 1. Tool Name
*   **`llmctx`** (all lowercase, inspired by `kubectx`).

### 2. Core Functionality
*   To manage different versions of CLI tool authentication/configuration files or directories.

### 3. Storage Mechanism
*   **Base Directory:** All managed configurations and metadata will be stored under `$HOME/.llmctx/`.
*   **Metadata File:** `$HOME/.llmctx/providers.json` will store metadata for each provider.
    *   For each provider, it must store:
        *   The provider's given name.
        *   The absolute path to the original configuration file/directory being managed.
        *   The `type` of the managed path (either "file" or "directory").
        *   The name of the currently active version.
*   **Version Storage:** `$HOME/.llmctx/providers/<provider_name>/versions/<version_name>` will store the actual copies of the configuration files or directories.

### 4. Commands and Their Specific Behaviors

#### 4.1. `llmctx add-provider`
*   **Purpose:** Registers a new configuration file or directory to be managed.
*   **User Interaction:**
    *   Prompts the user to "Enter a name for the provider:".
    *   Prompts the user to "Enter the absolute path to the configuration file or directory to manage:".
    *   If the provided path does not exist:
        *   Asks the user: "Path '<path>' does not exist. First create the file and then import it!".
    *   Prompts the user to "Enter a name for the initial version:". This name must be provided by the user; no automatic "initial" naming.
*   **Internal Logic:**
    *   Resolves `~` in the provided path to `$HOME`.
    *   Determines and stores the `type` of the managed path (file or directory) in `providers.json`.
    *   Copies the content of the original path (file or directory) to `$HOME/.llmctx/providers/<provider_name>/versions/<initial_version_name>`.
        *   Uses `cp` for files and `cp -r` for directories.
    *   Updates `providers.json` with the new provider's details and sets its `current_version` to the name of the initial version (provided).

#### 4.2. `llmctx add-version <provider_name> <version_name>`
*   **Purpose:** Saves the current state of a managed configuration file or directory as a new named version.
*   **User Interaction:** Takes `provider_name` and `version_name` as arguments.
*   **Internal Logic:**
    *   Retrieves the original path and type from `providers.json` for the given `provider_name`.
    *   Copies the current content of the original path to `$HOME/.llmctx/providers/<provider_name>/versions/<version_name>`.
        *   Uses `cp` for files and `cp -r` for directories.
    *   If a version with `version_name` already exists in storage, it should be overwritten (for directories, `rm -rf` the old one before copying).

#### 4.3. `llmctx set-version <provider_name> <version_name>`
*   **Purpose:** Replaces the active configuration file or directory at its original location with a chosen version from storage.
*   **User Interaction:** Takes `provider_name` and `version_name` as arguments.
*   **Internal Logic:**
    *   Retrieves the original path and type from `providers.json` for the given `provider_name`.
    *   First makes sure the current version of the file/folder is backed up in any of the versions. (Need to compare all versions)
        * If not, fail and warn the user that the current state of file is not backed up. If they're sure they can choose to continue by using a `--force` flag, otherwise remind them to add this as a version.
    *   Deletes the existing content at the original path (file or directory).
        *   Uses `rm` for files and `rm -rf` for directories.
        *   Ensures parent directories exist before copying the new version.
    *   Copies the content from `$HOME/.llmctx/providers/<provider_name>/versions/<version_name>` to the original path.
        *   Uses `cp` for files and `cp -r` for directories.
    *   Updates the `current_version` field for the `provider_name` in `providers.json`.

#### 4.4. `llmctx edit <provider_name>`
*   **Purpose:** Displays the absolute path to the managed configuration file or directory.
*   **User Interaction:** Takes `provider_name` as an argument.
*   **Internal Logic:**
    *   Retrieves the original path from `providers.json` for the given `provider_name`.
    *   Prints the absolute path to the console.
    *   Prints a reminder to the user to use `llmctx add-version <provider_name> <new_version_name>` after making changes.
*   **Crucial Constraint:** This command **must NOT** automatically open any text editor (e.g., `vi`, `nano`) or file browser.

#### 4.5. `llmctx list`
*   **Purpose:** Lists all managed providers and their versions.
*   **User Interaction:** No arguments.
*   **Internal Logic:**
    *   Reads `providers.json`.
    *   For each provider, prints:
        *   Provider Name.
        *   Original Path (e.g., `/Users/hb/.config/atlassian-cli/rovodev_config.yaml`).
        *   Type (e.g., "file" or "directory").
        *   Current Active Version.
        *   A list of all available saved versions for that provider.

### 5. Implementation Language and Framework
*   **Language:** Go (Golang).
*   **CLI Framework:** Cobra.

### 6. Development Process
*   **Strict Test-Driven Development (TDD):**
    *   For each piece of functionality, write unit and integration tests that initially fail.
    *   Implement the Go code to make those tests pass.
    *   Ensure all tests pass before moving to the next feature.
*   **Code Review:** The Go code will be presented for manual review after all tests are passing.

### 7. General Qualities
*   **Robustness:** The tool must be robust and not brittle (a key reason for switching from the shell script).
*   **Lightweight:** The final compiled binary should be lightweight.
