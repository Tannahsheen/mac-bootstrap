#!/usr/bin/env bash
set -e

DOTFILES_REPO="https://github.com/Tannahsheen/dotfiles"
TOOLS="$HOME/tools"

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
ok()   { echo -e "${G}✓${N} $*"; }
info() { echo -e "${Y}→${N} $*"; }
warn() { echo -e "${R}!${N} $*"; }

# ─── Homebrew ───────────────────────────────────────────────────────────────
info "Homebrew"
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
ok "brew ready"

# ─── Taps ───────────────────────────────────────────────────────────────────
brew tap FelixKratz/formulae 2>/dev/null || true

# ─── CLI tools ──────────────────────────────────────────────────────────────
info "CLI tools"
brew install \
    git wget curl ruby \
    neovim tmux rlwrap \
    nmap masscan ffuf feroxbuster \
    seclists \
    metasploit \
    proxychains-ng samba openldap \
    netexec kerbrute \
    nuclei amass \
    bettercap \
    sketchybar \
    pipx
ok "CLI tools done"

# ─── Cask apps ──────────────────────────────────────────────────────────────
info "Cask apps"
brew install --cask \
    iterm2 \
    sublime-text \
    nikitabobko/tap/aerospace \
    wireshark \
    zap \
    font-hack-nerd-font
ok "Cask apps done"

# ─── Python pentest tools ───────────────────────────────────────────────────
info "Python pentest tools (pipx)"
pipx ensurepath
pipx install impacket   || warn "impacket failed"
pipx install certipy-ad || warn "certipy-ad failed"
pipx install mitm6      || warn "mitm6 failed"
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
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
ok "Oh My Zsh ready"

# ─── ~/tools ────────────────────────────────────────────────────────────────
info "~/tools"
mkdir -p "$TOOLS"

if [ ! -d "$TOOLS/SecLists" ]; then
    git clone --depth 1 https://github.com/danielmiessler/SecLists "$TOOLS/SecLists"
    ok "SecLists cloned"
else
    ok "SecLists already present"
fi

declare -A COERCION_REPOS=(
    [PetitPotam]="https://github.com/topotam/PetitPotam"
    [DFSCoerce]="https://github.com/Wh04m1001/DFSCoerce"
    [ShadowCoerce]="https://github.com/ShutdownRepo/ShadowCoerce"
    [Responder]="https://github.com/lgandx/Responder"
)

for tool in "${!COERCION_REPOS[@]}"; do
    if [ ! -d "$TOOLS/$tool" ]; then
        git clone "${COERCION_REPOS[$tool]}" "$TOOLS/$tool" && ok "$tool cloned"
    else
        ok "$tool already present"
    fi
done

# ─── Dotfiles ───────────────────────────────────────────────────────────────
info "Dotfiles"
if [ ! -d "$HOME/dotfiles" ]; then
    git clone "$DOTFILES_REPO" "$HOME/dotfiles"
fi
bash "$HOME/dotfiles/install.sh"
ok "Dotfiles applied"

# ─── Commercial apps (detect only) ──────────────────────────────────────────
echo ""
info "Commercial apps"
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
        warn "$app — not found (install manually)"
    fi
done

# ─── Post-install notes ──────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────"
ok "Bootstrap complete"
echo ""
echo "Manual steps:"
echo "  brew services start sketchybar"
echo "  open -a AeroSpace"
echo "  Install ligolo-ng: https://github.com/nicocha30/ligolo-ng/releases"
echo "  Install gowitness: https://github.com/sensepost/gowitness/releases"
echo "─────────────────────────────────────────────────"
