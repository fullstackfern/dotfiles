# dotfiles

Personal macOS dotfiles for a fresh machine setup.

```bash
curl -fsSL https://raw.githubusercontent.com/fullstackfern/dotfiles/main/bootstrap.sh | zsh
```

## What it does

**Requirements** — Installs Xcode Command Line Tools and Homebrew if not already present, then runs `brew bundle` to install everything from the Brewfile.

**Dotfiles** — Symlinks config files from this repo directly into `$HOME`, so changes are tracked in git. Includes shell config (`.zshrc`) and tool configs under `.config/`.

**macOS settings** — Applies a set of `defaults write` preferences: faster key repeat, 24-hour clock, file extensions always shown, Finder path bar and folder-first sorting, screenshots saved to `~/Pictures/Screenshots`, and a few others.

**Dock** — Clears out default Apple apps and sets up a clean dock with your actual tools: VS Code, GitHub Desktop, 1Password, Claude, Obsidian, Edge, Outlook, Teams, Zoom, and a few others.

**Default apps** — Sets IINA as the default for audio and video files.

**Symlinks** — Creates any additional symlinks defined in `macos/symlinks.csv` (e.g. OneDrive folders).

## Apps installed

| Category | Apps |
|---|---|
| Dev tools | VS Code, JetBrains Toolbox, GitHub Desktop, Postman, Bruno |
| Productivity | Claude, 1Password, Obsidian, Microsoft Edge, Parallels, Zoom |
| CLIs | `git`, `gh`, `node`, `nvm`, `python`, `pyenv`, `eza`, `bat`, `fd`, `starship` |
| Fonts | Fira Code |
