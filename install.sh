#!/usr/bin/env bash
set -e

DOTFILES_REPO="https://github.com/Tannahsheen/mac-dotfiles"
TOOLS="$HOME/tools"
BIN="/opt/homebrew/bin"  # brew-managed bin, already in PATH on Apple Silicon

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
ok()   { echo -e "${G}✓${N} $*"; }
info() { echo -e "${Y}→${N} $*"; }
warn() { echo -e "${R}!${N} $*"; }

ARCH=$(uname -m)
[ "$ARCH" = "arm64" ] && DL_ARCH="arm64" || DL_ARCH="amd64"

# Download latest GitHub release asset matching a pattern
github_latest_binary() {
    local repo="$1" pattern="$2" dest="$3"
    local url
    url=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" \
          | grep browser_download_url \
          | grep "$pattern" \
          | grep -v '\.sha256\|\.md5' \
          | head -1 \
          | cut -d'"' -f4)
    if [ -n "$url" ]; then
        curl -sL "$url" -o "$dest"
        chmod +x "$dest"
        ok "$(basename "$dest") installed"
    else
        warn "$(basename "$dest") — no release found matching '$pattern'"
    fi
}

# ─── Homebrew ───────────────────────────────────────────────────────────────
info "Homebrew"
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
ok "brew ready"

# ─── Taps ───────────────────────────────────────────────────────────────────
brew tap FelixKratz/formulae      2>/dev/null || true
brew tap nikitabobko/tap          2>/dev/null || true

# ─── CLI tools ──────────────────────────────────────────────────────────────
info "CLI tools"
brew install \
    git wget curl ruby \
    neovim tmux rlwrap \
    nmap masscan rustscan \
    ffuf feroxbuster gobuster nikto \
    seclists \
    metasploit \
    proxychains-ng samba openldap \
    netexec kerbrute \
    hydra \
    john-jumbo hashcat \
    sqlmap \
    nuclei amass subfinder \
    bettercap \
    sketchybar \
    pipx
ok "CLI tools done"

# ─── Cask apps ──────────────────────────────────────────────────────────────
info "Cask apps"
brew install --cask \
    iterm2 \
    sublime-text \
    aerospace \
    docker \
    wireshark \
    zap \
    font-hack-nerd-font
ok "Cask apps done"

# ─── Python pentest tools (pipx) ────────────────────────────────────────────
info "Python pentest tools (pipx)"
pipx ensurepath

# PyPI
for pkg in impacket certipy-ad mitm6 patator enum4linux-ng ldapdomaindump dnsrecon; do
    pipx install "$pkg" 2>/dev/null && ok "$pkg" || warn "$pkg failed"
done

# From git
pipx install "git+https://github.com/aboul3la/Sublist3r"   2>/dev/null && ok "sublist3r"   || warn "sublist3r failed"
pipx install "git+https://github.com/fox-it/BloodHound.py" 2>/dev/null && ok "bloodhound"  || warn "bloodhound-py failed"
pipx install "git+https://github.com/Pennyw0rth/NetExec"   2>/dev/null && ok "netexec-git" || true  # already from brew, skip ok to avoid noise

ok "Python tools done"

# ─── Ruby tools ─────────────────────────────────────────────────────────────
info "evil-winrm"
gem install evil-winrm 2>/dev/null \
    || sudo gem install evil-winrm \
    || warn "evil-winrm failed — try: sudo gem install evil-winrm"
ok "evil-winrm done"

# ─── Oh My Zsh ──────────────────────────────────────────────────────────────
info "Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"   2>/dev/null || true
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
ok "Oh My Zsh ready"

# ─── Standalone binaries (gowitness, ligolo-ng) ─────────────────────────────
info "Standalone binaries"

if ! command -v gowitness &>/dev/null; then
    github_latest_binary \
        "sensepost/gowitness" \
        "darwin.*${DL_ARCH}" \
        "$BIN/gowitness"
fi

# ligolo-ng proxy (runs on attacker/this machine)
if ! command -v ligolo-proxy &>/dev/null; then
    url=$(curl -s "https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest" \
          | grep browser_download_url \
          | grep "proxy.*darwin.*${DL_ARCH}.*\.tar\.gz" \
          | head -1 \
          | cut -d'"' -f4)
    if [ -n "$url" ]; then
        tmpdir=$(mktemp -d)
        curl -sL "$url" | tar -xz -C "$tmpdir"
        install -m755 "$tmpdir/proxy" "$BIN/ligolo-proxy"
        rm -rf "$tmpdir"
        ok "ligolo-proxy installed"
    else
        warn "ligolo-ng — could not find release, download from https://github.com/nicocha30/ligolo-ng/releases"
    fi
fi

ok "Standalone binaries done"

# ─── ~/tools ────────────────────────────────────────────────────────────────
info "~/tools"
mkdir -p "$TOOLS"

if [ ! -d "$TOOLS/SecLists" ]; then
    git clone --depth 1 https://github.com/danielmiessler/SecLists "$TOOLS/SecLists"
    ok "SecLists cloned"
else
    ok "SecLists already present"
fi

declare -A TOOL_REPOS=(
    [PetitPotam]="https://github.com/topotam/PetitPotam"
    [DFSCoerce]="https://github.com/Wh04m1001/DFSCoerce"
    [ShadowCoerce]="https://github.com/ShutdownRepo/ShadowCoerce"
    [Responder]="https://github.com/lgandx/Responder"
    [BloodHound-CE]="https://github.com/SpecterOps/BloodHound"
)

for tool in "${!TOOL_REPOS[@]}"; do
    if [ ! -d "$TOOLS/$tool" ]; then
        git clone "${TOOL_REPOS[$tool]}" "$TOOLS/$tool" && ok "$tool cloned"
    else
        ok "$tool already present"
    fi
done

ok "~/tools done"

# ─── BloodHound CE ──────────────────────────────────────────────────────────
info "BloodHound CE"
BHCE_COMPOSE="$TOOLS/BloodHound-CE/examples/docker-compose/docker-compose.yml"
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    if [ -f "$BHCE_COMPOSE" ]; then
        docker compose -f "$BHCE_COMPOSE" up -d \
            && ok "BloodHound CE containers started — http://localhost:8080" \
            || warn "BloodHound CE failed to start"
    else
        warn "BloodHound CE compose file not found — check $TOOLS/BloodHound-CE"
    fi
else
    warn "Docker not running — start Docker Desktop, then: docker compose -f $BHCE_COMPOSE up -d"
fi

# ─── Dotfiles ───────────────────────────────────────────────────────────────
info "Dotfiles"
if [ ! -d "$HOME/mac-dotfiles" ]; then
    git clone "$DOTFILES_REPO" "$HOME/mac-dotfiles"
fi
bash "$HOME/mac-dotfiles/install.sh"
ok "Dotfiles applied"

# ─── Commercial apps (detect only) ──────────────────────────────────────────
echo ""
info "Commercial apps (manual install required)"
declare -A COMMERCIAL=(
    [Parallels]="/Applications/Parallels Desktop.app"
    [Office]="/Applications/Microsoft Word.app"
    [Claude]="/Applications/Claude.app"
    [ClickUp]="/Applications/ClickUp.app"
)
for app in "${!COMMERCIAL[@]}"; do
    if [ -d "${COMMERCIAL[$app]}" ]; then
        ok "$app — installed"
    else
        warn "$app — not found"
    fi
done

# ─── Summary ────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────"
ok "Bootstrap complete"
echo ""
echo "Start services:"
echo "  brew services start sketchybar"
echo "  open -a AeroSpace"
echo "  open -a Docker  # then rerun bootstrap for BloodHound CE"
echo ""
echo "Responder note: cloned to ~/tools/Responder"
echo "  Raw socket tools have limited functionality on macOS."
echo "  Use your Kali box for Responder/mitm6 in real engagements."
echo "────────────────────────────────────────────────────────"
