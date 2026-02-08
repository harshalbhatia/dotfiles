# Powerlevel10k to Starship Migration Notes

## Current P10k Configuration Summary

**Generated:** 2020-10-14
**Style:** Rainbow (colorful backgrounds), 2-line, nerdfont-complete

---

## Prompt Layout

### Left Prompt (Line 1)
| Segment | Description |
|---------|-------------|
| `dir` | Current directory (smart truncation to unique prefix) |
| `vcs` | Git status (custom formatter) |

### Left Prompt (Line 2)
- Empty (just the frame ornament `╰─`)

### Right Prompt (Line 1)
| Segment | When Shown |
|---------|------------|
| `status` | Exit code (checkmark on success, X on error) |
| `command_execution_time` | Commands > 3 seconds |
| `background_jobs` | When jobs are running |
| `direnv` | When direnv is active |
| `mise` | When mise is managing versions |
| `virtualenv` | Python venv active |
| `anaconda` | Conda env active |
| `pyenv` | Python version (non-global) |
| `goenv` | Go version (non-global) |
| `nodenv` | Node version (non-global) |
| `nodeenv` | Node env active |
| `rbenv` | Ruby version |
| `rvm` | Ruby version |
| `fvm` | Flutter version |
| `luaenv` | Lua version |
| `jenv` | Java version |
| `plenv` | Perl version |
| `phpenv` | PHP version |
| `scalaenv` | Scala version |
| `haskell_stack` | Haskell version |
| `kubecontext` | K8s context (only when typing kubectl/helm/k9s/etc.) |
| `terraform` | Terraform workspace |
| `aws` | AWS profile (only when typing aws/terraform/etc.) |
| `aws_eb_env` | Elastic Beanstalk env |
| `azure` | Azure account (only when typing az/terraform/etc.) |
| `gcloud` | GCloud project (only when typing gcloud/gcs) |
| `google_app_cred` | Google app credentials |
| `context` | user@hostname (only in SSH or root) |
| `nordvpn` | VPN status |
| `ranger` | Ranger shell |
| `nnn` | nnn shell |
| `vim_shell` | Vim :sh indicator |
| `midnight_commander` | MC shell |
| `nix_shell` | Nix shell |
| `vi_mode` | Vi mode indicator |
| `todo` | Todo.txt items |
| `timewarrior` | Time tracking |
| `taskwarrior` | Task count |
| `time` | Current time (HH:MM:SS) |

---

## Key Features to Replicate

### 1. Prompt Structure
- **2-line prompt** with frame/box characters
- **Transient prompt** - old prompts collapse to minimal
- **Instant prompt** - shows immediately while shell loads

### 2. Git Status (Custom Formatter)
```
branch ⇣42⇡42 *42 merge ~42 +42 !42 ?42
```
- `⇣` commits behind remote
- `⇡` commits ahead of remote
- `*` stashes
- `~` merge conflicts
- `+` staged changes
- `!` unstaged changes
- `?` untracked files
- Branch truncated at 32 chars

### 3. Directory Display
- Smart truncation to unique prefix
- Anchors at project markers (.git, package.json, Cargo.toml, etc.)
- Max length: 80 chars
- Hyperlinks: disabled

### 4. Command Execution Time
- Threshold: 3 seconds
- Format: `1d 2h 3m 4s`
- Precision: 0 (whole seconds)

### 5. Kubernetes Context
- Only shows when typing: `kubectl|helm|kubens|kubectx|oc|istioctl|kogito|k9s|helmfile`
- Format: `cluster-name/namespace` (hides default namespace)

### 6. Cloud Providers
- **AWS:** Only shows when typing `aws|awless|terraform|pulumi|terragrunt`
- **Azure:** Only shows when typing `az|terraform|pulumi|terragrunt`
- **GCloud:** Only shows when typing `gcloud|gcs`

### 7. Version Managers
All configured to hide when:
- Version matches global
- Version is "system"

### 8. Visual Style
- Nerd fonts: `nerdfont-complete` mode
- Separators: Slanted (powerline style)
- Colors: Rainbow theme with colored backgrounds
- Frame characters: `╭─`, `├─`, `╰─` on left; `─╮`, `─┤`, `─╯` on right
- Empty line before each prompt

---

## Starship Equivalent Config

### Priority Modules (YOU ACTUALLY USE)
Based on your oh-my-zsh plugins and config, these are what you likely need:

1. **directory** - with truncation
2. **git_branch** + **git_status** - detailed status
3. **cmd_duration** - 3s threshold
4. **character** - prompt symbol
5. **kubernetes** - context display
6. **python** - virtualenv/conda/pyenv
7. **nodejs** - if you do JS work
8. **time** - 24h format

### Lower Priority (conditional)
- aws, gcloud, azure (only when using those CLIs)
- terraform
- status (exit code)

---

## Starship Starter Config

```toml
# ~/.config/starship.toml

# Minimal 2-line prompt
format = """
$directory\
$git_branch\
$git_status\
$fill\
$kubernetes\
$python\
$nodejs\
$cmd_duration\
$time
$character"""

# Add newline before prompt
add_newline = true

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold cyan"

[git_branch]
symbol = ""
style = "bold purple"

[git_status]
format = '([$all_status$ahead_behind]($style) )'
style = "bold red"
stashed = "*"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇡${ahead_count}⇣${behind_count}"
conflicted = "~"
deleted = ""
renamed = ""
modified = "!"
staged = "+"
untracked = "?"

[cmd_duration]
min_time = 3_000  # 3 seconds
format = "[$duration]($style) "
style = "bold yellow"

[time]
disabled = false
format = "[$time]($style) "
time_format = "%H:%M:%S"
style = "bold dimmed white"

[kubernetes]
disabled = false
format = '[$symbol$context( \($namespace\))]($style) '
style = "bold blue"
# Only show when kubectl/helm are detected
detect_files = []
detect_folders = []
detect_extensions = []

[python]
format = '[${symbol}${pyenv_prefix}(${version})(\($virtualenv\))]($style) '
style = "bold yellow"

[nodejs]
format = "[$symbol($version)]($style) "
style = "bold green"

[fill]
symbol = " "
```

---

## Migration Checklist

- [ ] Install Starship: `brew install starship`
- [ ] Create config: `~/.config/starship.toml`
- [ ] Update `instant.zsh` to use Starship instead of P10k
- [ ] Test with `starship prompt`
- [ ] Verify nerd fonts render correctly
- [ ] Tune colors/symbols to preference
- [ ] Consider keeping P10k as fallback initially

---

## Notes

- Starship doesn't have "instant prompt" like P10k, but it's fast enough that you won't notice
- Starship doesn't have "transient prompt" built-in (old prompts stay full)
- For transient prompt in Starship, you'd need a zsh hook (more complex)
- Starship config is much simpler than P10k (good for maintenance)
