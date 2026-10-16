# Ubuntu manual restore checklist

This list covers programs or setup steps that are not installed automatically by `ubuntu-rebuild.sh`, mostly because they are distributed as AppImages / `.deb` files, require a user account, or depend on a GNOME Shell extension's compatibility with the installed GNOME version.

## Download manually

1. **Obsidian (AppImage)** — https://obsidian.md/download
   - Choose Linux → AppImage. Save it outside the Ubuntu partition if you want to keep it during a reinstall.
   - After downloading: `chmod u+x Obsidian-*.AppImage`; launch it. If the app specifically reports a sandbox launch issue, consult the current Obsidian instructions before adding launch flags.
   - The app's notes/vaults are separate from the application. Store your vault on a partition or drive that will not be formatted if you want to keep your notes.

2. **Cisco Packet Tracer** — https://www.netacad.com/courses/packet-tracer
   - Sign in/create a Cisco Networking Academy account if required, then download the Ubuntu/Linux installer provided there.
   - It is not installed by APT in this script. Once downloaded as a `.deb`, install from the download folder with: `sudo apt install ./<downloaded-file>.deb`.

3. **RustDesk (only if you still want it)** — https://rustdesk.com/download/
   - Earlier, you asked about installing RustDesk on Android. The Android app is separate from the Linux desktop package; install the Android version from the official app listing/source.
   - For Ubuntu, download the official Ubuntu `.deb`, then use `sudo apt install ./rustdesk-<version>.deb` from its download folder. It is intentionally not included by default because you did not confirm that you installed the Ubuntu client.

## Do not automatically restore these

- **DaVinci Resolve 19** — you previously removed it after it failed GPU/compute detection on the Radeon 610M / Mesa setup. The installation involved library compatibility workarounds and did not result in a working editor. This script intentionally does not reinstall it; use Kdenlive from APT unless you re-check current official Linux GPU requirements and compatibility.
- **All-in-One Clipboard / Clippo GNOME clipboard extensions** — you reported that the All-in-One Clipboard extension was glitchy in Brave and other applications. Check current compatibility with your installed GNOME Shell version before reinstalling any clipboard extension: https://extensions.gnome.org/
- **Exact GNOME icon/theme/thumbnail fixes** — the system previously showed warning-triangle placeholder icons in Settings, Tweaks and Brave downloads. That was not conclusively fixed, so don't copy a guessed icon-theme workaround from an old setup. Diagnose fresh if it happens again.
- **Docker / Kubernetes / other roadmap topics** — these were discussed as learning topics, but prior history doesn't confirm a working installation. They are not installed by this script to avoid adding a large, unnecessary toolchain. Install them only when you're ready to use them.
- **Android-only tools** — Termux is installed on Android, not Ubuntu. Install Termux and Tailscale on the Android device separately if you still use that SSH/Tailscale workflow.

## Tailscale + SSH after running the script

The script installs Tailscale (if you accepted the prompt) and the OpenSSH server package, but it does not automatically enroll your machine into a tailnet or enable inbound SSH.

- Enrol this machine in Tailscale: `sudo tailscale up`
- If this Ubuntu machine should accept SSH connections: `sudo systemctl enable --now ssh`
- Then test with the machine's Tailscale IP/name from Termux. Only enable SSH if you intend to connect to this Ubuntu machine remotely.

## Things that are installed by the script

- APT: build-essential, Git/Git LFS, curl/wget, unzip/zip, Python 3 + venv + pipx, Node.js/npm, SQLite, FFmpeg, Kdenlive, Neovim, Kitty, Ghostty (if available in the enabled Ubuntu repositories), `fzf`, `ripgrep`, `fd-find`, `bat`, `btop`, `jq`, `tmux`, `htop`, `ncdu`, fonts (Fira Code / JetBrains Mono), Fastfetch, GParted, GNOME Tweaks and Extension Manager, OpenSSH server, and supporting libraries.
- Official third-party repos (only if accepted): Brave Browser, Visual Studio Code, and Tailscale.
- uv (Astral's standalone Python CLI/project manager) and yt-dlp via `uv tool install`; Ruff is also installed as an isolated CLI tool.
- Common VS Code extensions for Python/Pylance, C/C++, Live Server, and Prettier, if VS Code is installed.
- Starter Tokyo-Night-inspired Kitty and Ghostty configs are created only if those config files don't already exist. A minimal Neovim `init.lua` is created only if no Neovim config already exists.

## Save this before reformatting

Keep both `ubuntu-rebuild.sh` and this checklist on the Windows `OS` partition or a USB drive. Do not store the only copy on the Ubuntu partition that you're formatting.
