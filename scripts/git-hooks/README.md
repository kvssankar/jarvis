# Git Hooks for Shots Studio

This directory contains Git hooks that automate various tasks during development.

## Available Hooks

### pre-commit
- **Purpose**: Automatically increments the patch version in `pubspec.yaml` before each commit **only when there are changes in the `shots_studio/` directory**
- **Example**: `1.7.0+1` → `1.7.1+1`
- **Behavior**: 
  - Checks if there are staged changes in `shots_studio/` directory
  - If no Flutter app changes detected, skips version increment
  - If changes found, reads current version from `shots_studio/pubspec.yaml`
  - Increments the patch version (third number)
  - Resets build number to `+1`
  - Adds the updated `pubspec.yaml` to the commit

### post-commit
- **Purpose**: Updates `flutter.version` file with the currently running Flutter version
- **Behavior**:
  - Detects current Flutter version using `flutter --version`
  - Compares with stored version in `shots_studio/flutter.version`
  - If different, updates the file and creates an additional commit
  - Helps track which Flutter version was used for each commit

### commit-msg
- **Purpose**: (If present) Validates or formats commit messages
- **Note**: May include additional message formatting rules

### post-checkout
- **Purpose**: (If present) Performs actions after switching branches or checking out
- **Note**: May include cleanup or setup tasks

## Installation

Run the setup script from the project root:

```bash
./scripts/setup-git-hooks.sh
```

This will:
1. Copy all hooks to `.git/hooks/`
2. Make them executable
3. Show confirmation of installed hooks

## Manual Installation

If you prefer to install hooks manually:

```bash
# From project root
cp scripts/git-hooks/* .git/hooks/
chmod +x .git/hooks/*
```

## Workflow Example

1. Make changes to your code
2. Run `git add .` and `git commit -m "feat: add new feature"`
3. **pre-commit** hook runs:
   - Checks for changes in `shots_studio/` directory
   - If Flutter app changes found: Version bumped `1.7.0+1` → `1.7.1+1`
   - If only docs/scripts changes: Version unchanged (skipped)
   - Updated `pubspec.yaml` included in commit (if incremented)
4. Commit completes with conditional version increment
5. **post-commit** hook runs:
   - Checks Flutter version (e.g., `3.32.4`)
   - Updates `flutter.version` file if changed
   - Creates additional commit if needed: `"chore: update Flutter version to 3.32.4"`

## Disabling Hooks

To temporarily disable hooks:

```bash
# Disable all hooks
git config core.hooksPath /dev/null

# Re-enable hooks
git config --unset core.hooksPath
```

To permanently remove:

```bash
rm .git/hooks/pre-commit
rm .git/hooks/post-commit
# etc.
```

## Troubleshooting

### Hook not running
- Ensure hooks are executable: `chmod +x .git/hooks/*`
- Check if hooks path is set: `git config core.hooksPath`

### Flutter version not detected
- Ensure Flutter is in PATH: `flutter --version`
- Check if you're in the correct directory (project root)

### Version conflicts
- If you need to manually set versions, edit the files directly:
  - `shots_studio/pubspec.yaml` for app version
  - `shots_studio/flutter.version` for Flutter version
