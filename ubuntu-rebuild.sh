#!/usr/bin/env bash
# Ubuntu rebuild helper tailored to the software/tools discussed in prior chats.
# Run as the normal user: ./ubuntu-rebuild.sh
# This script NEVER partitions, formats, mounts, or deletes disks/files.
set -Eeuo pipefail

LOG_FILE="$HOME/ubuntu-rebuild-$(date +%Y%m%d-%H%M%S).log"
FAILED_ITEMS=()

log() { printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG_FILE"; }
warn() { printf '\nWARNING: %s\n' "$*" | tee -a "$LOG_FILE" >&2; }
ask_yes() {
  local prompt="$1" answer
  read -r -p "$prompt [Y/n] " answer || answer=""
  [[ -z "$answer" || "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

if [[ ${EUID} -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo. The script uses sudo when needed."
  exit 1
fi
if [[ ! -r /etc/os-release ]]; then
  echo "Could not identify the operating system."
  exit 1
fi
# shellcheck source=/etc/os-release
source /etc/os-release
if [[ "${ID:-}" != ubuntu ]]; then
  echo "This script is for Ubuntu. Detected: ${PRETTY_NAME:-unknown}."
  exit 1
fi

cat <<'INTRO'
Ubuntu rebuild setup
====================
Installs the tools and applications discussed: development toolchains,
Neovim, Kitty, Ghostty, FFmpeg, Kdenlive, Brave, VS Code, Tailscale,
and yt-dlp via uv. It also seeds basic Tokyo-Night-inspired terminal configs.

It will NOT format disks, partition disks, delete files, or overwrite existing
Kitty/Ghostty/Neovim configurations. Third-party repositories are optional.
Some apps (Obsidian AppImage, Cisco Packet Tracer, and GNOME clipboard extensions)
are intentionally left for manual installation; see the companion manual list.
INTRO
printf 'Log: %s\n' "$LOG_FILE"
if ! ask_yes "Continue with Ubuntu setup?"; then
  echo "Cancelled."
  exit 0
fi

log "Updating APT package lists"
if ! sudo apt-get update; then
  echo "APT update failed. Check your internet connection and apt sources, then retry."
  exit 1
fi

# Packages commonly available in Ubuntu. Missing names are skipped and reported.
packages=(
  build-essential make gcc g++ gdb clang clang-format cmake ninja-build pkg-config
  git git-lfs curl wget ca-certificates gnupg lsb-release software-properties-common
  unzip zip p7zip-full unrar-free tree xdg-utils
  neovim kitty ghostty
  python3 python3-venv python3-pip python3-dev pipx
  nodejs npm sqlite3 sqlitebrowser
  ffmpeg kdenlive
  ripgrep fd-find fzf bat btop jq tmux htop ncdu wl-clipboard xclip
  fonts-firacode fonts-jetbrains-mono fastfetch gparted
  gnome-tweaks gnome-shell-extension-manager gnome-shell-extensions
  openssh-server libnss3 libfuse2t64
  shellcheck
)

available=()
skipped=()
for pkg in "${packages[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    available+=("$pkg")
  else
    skipped+=("$pkg")
  fi
done

log "Installing Ubuntu repository packages"
if ((${#available[@]})); then
  if ! sudo apt-get install -y "${available[@]}"; then
    FAILED_ITEMS+=("Some Ubuntu repository packages (review apt output and retry missing packages)")
  fi
fi
if ((${#skipped[@]})); then
  warn "These package names were not found in enabled repositories and were skipped: ${skipped[*]}"
fi

# Add official Brave + VS Code repositories; Tailscale uses its official installer.
# These are optional so the user controls adding third-party package sources.
if ask_yes "Add official Brave and Microsoft VS Code repositories, and install Tailscale?"; then
  log "Setting up Brave Browser from Brave's official APT repository"
  if curl -fsSLo /tmp/brave-browser-archive-keyring.gpg \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg &&
     curl -fsSLo /tmp/brave-browser-release.sources \
      https://brave-browser-apt-release.s3.brave.com/brave-browser.sources &&
     sudo install -d -m 0755 /usr/share/keyrings &&
     sudo install -m 0644 /tmp/brave-browser-archive-keyring.gpg /usr/share/keyrings/brave-browser-archive-keyring.gpg &&
     sudo install -m 0644 /tmp/brave-browser-release.sources /etc/apt/sources.list.d/brave-browser-release.sources &&
     sudo apt-get update && sudo apt-get install -y brave-browser; then
    log "Brave Browser installed"
  else
    FAILED_ITEMS+=("Brave Browser repository/install")
    warn "Brave installation failed; see the official manual instructions in the companion file."
  fi

  log "Setting up Microsoft VS Code's official APT repository"
  if curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor --yes -o /tmp/microsoft-vscode.gpg &&
     sudo install -m 0644 /tmp/microsoft-vscode.gpg /usr/share/keyrings/microsoft-vscode.gpg &&
     printf '%s\n' \
       'Types: deb' \
       'URIs: https://packages.microsoft.com/repos/code' \
       'Suites: stable' \
       'Components: main' \
       'Architectures: amd64,arm64,armhf' \
       'Signed-By: /usr/share/keyrings/microsoft-vscode.gpg' \
       | sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null &&
     sudo apt-get update && sudo apt-get install -y code; then
    log "VS Code installed"
  else
    FAILED_ITEMS+=("Visual Studio Code repository/install")
    warn "VS Code installation failed; see the official manual instructions in the companion file."
  fi

  log "Installing Tailscale using its official Linux installer"
  if curl -fsSL https://tailscale.com/install.sh -o /tmp/tailscale-install.sh &&
     sudo sh /tmp/tailscale-install.sh; then
    log "Tailscale installed. Authentication is intentionally left for you to do manually."
  else
    FAILED_ITEMS+=("Tailscale install")
    warn "Tailscale installation failed; see the official manual instructions in the companion file."
  fi
else
  log "Skipped third-party repositories and Tailscale, as requested."
fi

# Install uv via Astral's official standalone installer and yt-dlp in an isolated tool env.
log "Installing uv and yt-dlp (the Python application, not the Ubuntu package)"
if command -v uv >/dev/null 2>&1; then
  UV_BIN="$(command -v uv)"
else
  if curl -LsSf https://astral.sh/uv/install.sh -o /tmp/uv-install.sh && sh /tmp/uv-install.sh; then
    UV_BIN="$HOME/.local/bin/uv"
  else
    UV_BIN=""
    FAILED_ITEMS+=("uv installer")
  fi
fi
if [[ -n "$UV_BIN" && -x "$UV_BIN" ]]; then
  if ! "$UV_BIN" tool install yt-dlp; then
    # Tool may already exist or need an update; try upgrading before recording a failure.
    if ! "$UV_BIN" tool upgrade yt-dlp; then
      FAILED_ITEMS+=("yt-dlp via uv")
    fi
  fi
else
  warn "uv was not found; install it from https://docs.astral.sh/uv/ and then run: uv tool install yt-dlp"
fi

# Install useful Python linting/formatting CLI, without polluting system Python.
if [[ -n "${UV_BIN:-}" && -x "${UV_BIN:-}" ]]; then
  if ! "$UV_BIN" tool install ruff; then
    warn "Ruff tool installation did not complete; you can retry with: uv tool install ruff"
  fi
fi

# Optional VS Code extensions for the user's Python, C/C++, and HTML/CSS/JS work.
if command -v code >/dev/null 2>&1; then
  log "Installing common VS Code extensions"
  for extension in ms-python.python ms-python.vscode-pylance ms-vscode.cpptools ritwickdey.LiveServer esbenp.prettier-vscode; do
    if ! code --install-extension "$extension" --force; then
      warn "VS Code extension did not install: $extension"
    fi
  done
fi

# Seed Kitty only if there is no existing config. The config uses a Tokyo-Night-inspired palette.
kitty_dir="$HOME/.config/kitty"
kitty_conf="$kitty_dir/kitty.conf"
if [[ ! -e "$kitty_conf" ]]; then
  mkdir -p "$kitty_dir"
  cat > "$kitty_conf" <<'KITTY'
# Generated by ubuntu-rebuild.sh; Tokyo-Night-inspired starter config.
font_family JetBrains Mono
font_size 11.5
background #1a1b26
foreground #c0caf5
background_opacity 0.92
cursor_shape block
cursor #c0caf5
cursor_text_color #1a1b26
selection_background #33467c
selection_foreground #c0caf5
url_color #7aa2f7
active_border_color #7aa2f7
inactive_border_color #3b4261
hide_window_decorations no
window_padding_width 8
tab_bar_style fade
active_tab_foreground #1a1b26
active_tab_background #7aa2f7
inactive_tab_foreground #a9b1d6
inactive_tab_background #24283b

# Clipboard (Super is the Windows key on a standard PC keyboard).
map super+c copy_to_clipboard
map super+v paste_from_clipboard

# Tabs.
map ctrl+tab next_tab
map ctrl+shift+tab previous_tab
map ctrl+1 goto_tab 1
map ctrl+2 goto_tab 2
map ctrl+3 goto_tab 3
map ctrl+4 goto_tab 4
map ctrl+5 goto_tab 5
map ctrl+6 goto_tab 6

# Scrollback.
map ctrl+shift+up scroll_line_up
map ctrl+shift+down scroll_line_down
map ctrl+shift+page_up scroll_page_up
map ctrl+shift+page_down scroll_page_down
map ctrl+shift+home scroll_home
map ctrl+shift+end scroll_end

# ANSI palette.
color0 #15161e
color1 #f7768e
color2 #9ece6a
color3 #e0af68
color4 #7aa2f7
color5 #bb9af7
color6 #7dcfff
color7 #a9b1d6
color8 #414868
color9 #f7768e
color10 #9ece6a
color11 #e0af68
color12 #7aa2f7
color13 #bb9af7
color14 #7dcfff
color15 #c0caf5
KITTY
  log "Created starter Kitty config at $kitty_conf"
else
  log "Kitty config already exists; left it unchanged: $kitty_conf"
fi

# Seed Ghostty only if absent; custom palette avoids depending on a theme name.
ghostty_dir="$HOME/.config/ghostty"
ghostty_conf="$ghostty_dir/config"
if [[ ! -e "$ghostty_conf" ]]; then
  mkdir -p "$ghostty_dir"
  cat > "$ghostty_conf" <<'GHOSTTY'
# Generated by ubuntu-rebuild.sh; Tokyo-Night-inspired starter config.
font-family = JetBrains Mono
font-size = 11
background = 1a1b26
foreground = c0caf5
background-opacity = 0.92
cursor-color = c0caf5
cursor-text = 1a1b26
selection-background = 33467c
selection-foreground = c0caf5
cursor-style = block
window-padding-x = 8
window-padding-y = 8
window-decoration = true

palette = 0=#15161e
palette = 1=#f7768e
palette = 2=#9ece6a
palette = 3=#e0af68
palette = 4=#7aa2f7
palette = 5=#bb9af7
palette = 6=#7dcfff
palette = 7=#a9b1d6
palette = 8=#414868
palette = 9=#f7768e
palette = 10=#9ece6a
palette = 11=#e0af68
palette = 12=#7aa2f7
palette = 13=#bb9af7
palette = 14=#7dcfff
palette = 15=#c0caf5

keybind = super+c=copy_to_clipboard
keybind = super+v=paste_from_clipboard
keybind = ctrl+tab=next_tab
keybind = ctrl+shift+tab=previous_tab
keybind = ctrl+1=goto_tab:1
keybind = ctrl+2=goto_tab:2
keybind = ctrl+3=goto_tab:3
keybind = ctrl+4=goto_tab:4
keybind = ctrl+5=goto_tab:5
keybind = ctrl+6=goto_tab:6
GHOSTTY
  log "Created starter Ghostty config at $ghostty_conf"
else
  log "Ghostty config already exists; left it unchanged: $ghostty_conf"
fi

# Preserve existing Bash rc. Add idempotent aliases only once.
marker='# >>> ubuntu-rebuild aliases >>>'
if ! grep -Fq "$marker" "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'BASHRC'

# >>> ubuntu-rebuild aliases >>>
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then alias bat='batcat'; fi
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then alias fd='fdfind'; fi
# <<< ubuntu-rebuild aliases <<<
BASHRC
  log "Added aliases to ~/.bashrc"
else
  log "Alias block already exists; left ~/.bashrc unchanged"
fi

# Minimal Neovim defaults only if no config exists.
nvim_dir="$HOME/.config/nvim"
if [[ ! -e "$nvim_dir/init.lua" && ! -e "$nvim_dir/init.vim" ]]; then
  mkdir -p "$nvim_dir"
  cat > "$nvim_dir/init.lua" <<'LUA'
-- Safe starter settings. Add plugins/colorschemes later as desired.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
LUA
  log "Created minimal Neovim config at $nvim_dir/init.lua"
else
  log "Neovim config already exists; left it unchanged"
fi

cat <<'DONE'

Setup script has finished.

Next steps:
  1. Open a new terminal (or run: source ~/.bashrc).
  2. Authenticate Tailscale if installed: sudo tailscale up
  3. If you need this machine as an SSH host: sudo systemctl enable --now ssh
  4. Install Obsidian AppImage and Cisco Packet Tracer manually; see the companion list.
  5. Do not reinstall DaVinci Resolve on this setup without rechecking hardware/compute support.

Useful checks:
  nvim --version
  kitty --version
  ghostty --version
  python3 --version
  uv --version
  yt-dlp --version
  ffmpeg -version
  code --version
DONE

if ((${#FAILED_ITEMS[@]})); then
  printf '\nSome steps need attention:\n' | tee -a "$LOG_FILE"
  printf ' - %s\n' "${FAILED_ITEMS[@]}" | tee -a "$LOG_FILE"
fi
printf '\nFull log: %s\n' "$LOG_FILE"
printf 'Manual restore checklist: download ubuntu-manual-restore.md from the same location as this script.\n'
