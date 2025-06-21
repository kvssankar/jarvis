#!/bin/bash

# Script to set up Git hooks for the Shots Studio project
# Run this script from the project root directory

set -e

PROJECT_ROOT="$(pwd)"
HOOKS_DIR="$PROJECT_ROOT/scripts/git-hooks"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "Setting up Git hooks for Shots Studio..."

# Check if we're in the right directory
if [ ! -f "shots_studio/pubspec.yaml" ]; then
    echo "Error: This script should be run from the project root directory (where shots_studio/ folder is located)"
    exit 1
fi

# Check if .git directory exists
if [ ! -d ".git" ]; then
    echo "Error: No .git directory found. Make sure you're in a Git repository."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$GIT_HOOKS_DIR"

# Copy and link all hooks
for hook_file in "$HOOKS_DIR"/*; do
    if [ -f "$hook_file" ]; then
        hook_name=$(basename "$hook_file")
        target_file="$GIT_HOOKS_DIR/$hook_name"
        
        echo "Installing $hook_name hook..."
        
        # Copy the hook file
        cp "$hook_file" "$target_file"
        
        # Make it executable
        chmod +x "$target_file"
        
        echo "✓ $hook_name hook installed"
    fi
done

echo ""
echo "Git hooks installation complete!"
echo ""
echo "Installed hooks:"
echo "  - pre-commit: Auto-increments version in pubspec.yaml"
echo "  - post-commit: Updates flutter.version file with current Flutter version"
echo "  - commit-msg: (if exists) Message formatting"
echo "  - post-checkout: (if exists) Post-checkout actions"
echo ""
echo "You can now make commits and the hooks will run automatically."
