#!/bin/bash
set -euo pipefail

DOTFILES_REPO="https://github.com/fullstackfern/dotfiles.git"
DOTFILES_DIR="$HOME/Developer/.dotfiles"
GIT_BRANCH="${1:-main}"
GIT_FILE_PREFIX=".git"

# Output formatting ----------------------------------------------------------
info()    { echo "[dotfiles] $*"; }
success() { echo "[dotfiles] ✓ $*"; }
error()   { echo "[dotfiles] ✗ $*" >&2; }

info "Installing requirements..."

# Xcode Command Line Tools ----------------------------------------------------
if ! xcode-select -p &>/dev/null; then
  info "Xcode Command Line Tools must be installed manually."
  xcode-select --install

  info "  Re-run this script once installed."
  exit 0
fi

success "Xcode Command Line Tools already installed."

# Homebrew --------------------------------------------------------------------
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  eval "$(/opt/homebrew/bin/brew shellenv)" # Add Homebrew to PATH for the rest of this script
  success "Homebrew installed successfully."
else
  info "Updating Homebrew..."
  brew update --quiet
  success "Homebrew is up to date."
fi

# Clone dotfiles repo ---------------------------------------------------------
if [[ -d "$DOTFILES_DIR" ]]; then
  info "Updating dotfiles from '$GIT_BRANCH'..."
  git -C "$DOTFILES_DIR" fetch
  git -C "$DOTFILES_DIR" checkout "$GIT_BRANCH"
  git -C "$DOTFILES_DIR" pull
  success "dotfiles up to date."
else
  info "Cloning dotfiles from '$GIT_BRANCH' to $DOTFILES_DIR..."
  mkdir -p "$DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  git -C "$DOTFILES_DIR" checkout "$GIT_BRANCH"
  success "dotfiles cloned successfully."
fi

# Symlinks --------------------------------------------------------------------
info "Symlinking dotfiles..."
for dir in "$DOTFILES_DIR"/.[^.]*/; do
  name=$(basename "$dir")
  [[ "$name" == "$GIT_FILE_PREFIX"* ]] && continue
  while IFS= read -r file; do
    rel="${file#"$DOTFILES_DIR"/}"
    target="$HOME/$rel"
    mkdir -p "$(dirname "$target")"
    ln -sfn "$file" "$target" && success "$target → $file" || { error "Failed to symlink $rel"; }
  done <<EOF
$(find "$dir" -type f -not -name ".DS_Store")
EOF
done
if [[ -f "$DOTFILES_DIR/.gitignore" ]]; then
  ln -sfn "$DOTFILES_DIR/.gitignore" "$HOME/.gitignore" && success "$HOME/.gitignore → $DOTFILES_DIR/.gitignore" || { error "Failed to symlink .gitignore"; }
fi

# macOS Settings --------------------------------------------------------------
MACOS_SETTINGS="$DOTFILES_DIR/macos/settings.csv"
if [[ -f "$MACOS_SETTINGS" ]]; then
  info "Applying macOS settings..."
  dock_settings_changed=false
  finder_settings_changed=false
  screencapture_settings_changed=false
  while IFS=, read -r domain key type value; do
    [[ -z "$domain" || "$domain" == \#* || "$domain" =~ ^[[:space:]]*$ ]] && continue
    defaults write "$domain" "$key" -"$type" "$value" && success "$domain $key = $value" || { error "Failed to set $domain $key"; }
    [[ "$domain" == "com.apple.dock" ]] && dock_settings_changed=true
    [[ "$domain" == "com.apple.finder" ]] && finder_settings_changed=true
    [[ "$domain" == "com.apple.screencapture" ]] && screencapture_settings_changed=true
  done < "$MACOS_SETTINGS"
  if [[ "$dock_settings_changed" == true ]]; then
    killall Dock
  fi
  if [[ "$finder_settings_changed" == true ]]; then
    killall Finder
  fi
  if [[ "$screencapture_settings_changed" == true ]]; then
    mkdir -p "$HOME/Pictures/Screenshots"
  fi
fi

# Brewfile ----------------------------------------------------------------------
info "Installing Brewfile dependencies..."
brew bundle --global
success "Brewfile dependencies installed."

# File Default Apps -----------------------------------------------------------
FILE_DEFAULTS="$DOTFILES_DIR/macos/file-defaults.csv"
if [[ -f "$FILE_DEFAULTS" ]] && grep -qE '^[^#[:space:]]' "$FILE_DEFAULTS"; then
  info "Setting default apps..."
  while IFS=, read -r bundle type; do
    [[ -z "$bundle" || "$bundle" == \#* || "$bundle" =~ ^[[:space:]]*$ ]] && continue
    duti -s "$bundle" "$type" all && success "$type → $bundle" || { error "Failed to set default for $type"; }
  done < "$FILE_DEFAULTS"
fi

info "Running Homebrew cleanup..."
brew cleanup || { error "Unable to perform homebrew cleanup"; }
success "Homebrew cleanup complete."

# Dock ------------------------------------------------------------------------
DOCK_REMOVE="$DOTFILES_DIR/macos/dock/remove.txt"
DOCK_ADD="$DOTFILES_DIR/macos/dock/add.txt"
dock_changed=false

if [[ -f "$DOCK_REMOVE" ]] && grep -qE '^[^#[:space:]]' "$DOCK_REMOVE"; then
  info "Removing apps from dock..."
  while IFS= read -r app; do
    [[ -z "$app" || "$app" == \#* ]] && continue
    dockutil --remove "$app" --no-restart || true
    dock_changed=true
  done < "$DOCK_REMOVE"
fi

if [[ -f "$DOCK_ADD" ]] && grep -qE '^[^#[:space:]]' "$DOCK_ADD"; then
  info "Adding apps to dock..."
  existing_dock=$(dockutil --list 2>/dev/null || true)
  dock_apps=()
  while IFS= read -r line; do
    dock_apps+=("$line")
  done <<EOF
$(grep -E '^[^#[:space:]]' "$DOCK_ADD")
EOF
  for (( i=${#dock_apps[@]}-1; i>=0; i-- )); do
    app="${dock_apps[$i]}"
    [[ "$app" != */* ]] && app="/Applications/${app}.app"
    dockutil --add "$app" --no-restart || true
    dock_changed=true
  done
  for (( i=${#dock_apps[@]}-1; i>=0; i-- )); do
    app="${dock_apps[$i]}"
    [[ "$app" != */* ]] && app="/Applications/${app}.app"
    app_name=$(basename "$app" .app)
    if ! echo "$existing_dock" | grep -q "$app_name"; then
      dockutil --move "$app" --position beginning --no-restart || true
    fi
  done
fi

if [[ "$dock_changed" == true ]]; then
  killall Dock
  success "Dock configured."
fi
