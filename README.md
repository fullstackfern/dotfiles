# dotfiles

Personal macOS dotfiles for a fresh machine setup.

## Bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/fullstackfern/dotfiles/main/bootstrap.sh | zsh
```

This will:

- Install Xcode Command Line Tools (if needed)
- Install Homebrew (or update if already installed)
- Clone this repo to `~/Developer/.dotfiles`
