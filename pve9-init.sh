#!/bin/bash
set -euo pipefail
LOGFILE="/var/log/proxmox-init.log"
exec > >(tee -a "$LOGFILE")
exec 2>&1
echo "=== PROXMOX 9 INIT START $(date) ==="

trap 'echo "ERROR at line $LINENO – check $LOGFILE"; exit 1' ERR

# ==============================================================
# 1. Initial Package Update
# ==============================================================
echo "1. Updating system"
apt update
apt -y full-upgrade

# ==============================================================
# 2. Install every tool you will ever need
# ==============================================================
echo "2. Installing packages"
# Core packages (required)
apt -y install xterm plocate ipmiutil openipmi net-tools htop btop zip unzip bind9-dnsutils cpanminus curl wget bat dmidecode fdutils fd-find ugrep gcc g++ git imagemagick guestfs-tools libvirt-clients libguestfs-rescue guestfish guestfs-tools amd64-microcode vivid parted nano python3-json5 nvme-cli cpuinfo smartmontools bash-completion rsyslog proxmox-firewall build-essential screen mtr ruby snmp snmpd starship zram-tools fzf ripgrep jq dnsutils rsync gnupg tmux fonts-powerline fonts-font-awesome yamllint

# Optional packages (with error tolerance)
optional_packages="libguestfs-tools"  # if any extras needed
for pkg in $optional_packages; do
    apt -y install "$pkg" || echo "WARNING: Optional package $pkg failed to install"
done

echo "All packages installed."

# ==============================================================
# 3. .bashrc (hyper-focused version)
# ==============================================================
echo "3. Installing .bashrc"
cd /root
if [ -f .bashrc ]; then
    cp .bashrc .bashrc.bak
fi
wget -qO .bashrc https://github.com/hyper-focused/proxmox9-init/raw/refs/heads/main/bashrc

# ==============================================================
# 4. NVM + Direnv (required by .bashrc)
# ==============================================================
echo "4. Installing NVM & Direnv"
if [ ! -d ~/.nvm ]; then
    git clone https://github.com/nvm-sh/nvm.git ~/.nvm
    export NVM_DIR="$HOME/.nvm"
    . "$NVM_DIR/nvm.sh"
    nvm install --lts || echo "WARNING: NVM LTS install skipped"
fi

if [ ! -d ~/.local/share/direnv ]; then
    mkdir -p ~/.local/share
    git clone https://github.com/direnv/direnv.git ~/.local/share/direnv
    (cd ~/.local/share/direnv && make install) || echo "WARNING: Direnv build skipped"
fi

# ==============================================================
# 5. batcat theme
# ==============================================================
echo "5. Configuring batcat"
mkdir -p /root/.config/bat
batcat --generate-config-file 2>/dev/null || true
cat > /root/.config/bat/config << 'EOF'
--theme="Monokai Extended"
--italic-text=always
EOF

# ==============================================================
# 6. Starship prompt
# ==============================================================
echo "6. Installing Starship config"
mkdir -p ~/.config
wget -qO ~/.config/starship.toml https://github.com/smithumble/starship-cockpit/raw/refs/heads/main/starship.toml

# ==============================================================
# 7. Nerd Font (FiraCode)
# ==============================================================
echo "7. Installing FiraCode Nerd Font"
mkdir -p /usr/local/share/fonts/nerdfonts
cd /usr/local/share/fonts/nerdfonts
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
unzip -qo FiraCode.zip
fc-cache -fv
cd -

# ==============================================================
# 8. nano syntax highlighting (scopatz)
# ==============================================================
echo "8. Installing nano syntax"
mkdir -p /root/.nano
if [ ! -d /root/.nano ]; then
    git clone https://github.com/scopatz/nanorc.git /root/.nano
fi
cat > /root/.nanorc << 'EOF'
# nano syntax – auto-generated
EOF
for f in /root/.nano/*.nanorc; do
    if [ -f "$f" ]; then
        echo "include \"$f\"" >> /root/.nanorc
    fi
done

# ==============================================================
# 9. Hardened SSHD config
# ==============================================================
echo "9. Installing hardened sshd_config"
SSHD="/etc/ssh/sshd_config"
if [ ! -f /etc/ssh/sshd_config.orig ]; then
    cp "$SSHD" /etc/ssh/sshd_config.orig
fi
wget -qO "$SSHD.new" https://github.com/hyper-focused/proxmox9-init/raw/refs/heads/main/sshd_config
if sshd -t -f "$SSHD.new" 2>/dev/null; then
    mv "$SSHD.new" "$SSHD"
    systemctl reload sshd
    echo "SSHD config applied and reloaded"
else
    echo "WARNING: SSHD config validation failed – keeping original"
    rm -f "$SSHD.new"
fi

# ==============================================================
# DONE
# ==============================================================
echo "=== ALL DONE $(date) ==="
echo "Log saved to: $LOGFILE"
echo "Next steps:"
echo "  source ~/.bashrc"
echo "  tmux new-session  # for session management"
echo "  nano test.py      # to test syntax highlighting"
echo "  bat /etc/hosts    # to test bat theme"
echo "Open a NEW terminal to see Starship + Nerd Fonts in action!"
