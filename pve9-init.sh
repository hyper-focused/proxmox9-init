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
apt update && apt -y full-upgrade

# ==============================================================
# 2. Install every tool you will ever need
# ==============================================================
echo "2. Installing packages"
apt -y install \
  xterm plocate ipmiutil openipmi net-tools htop btop zip unzip \
  bind9-dnsutils cpanminus curl wget bat dmidecode fdutils fd-find ugrep \
  gcc g++ git imagemagick guestfs-tools libvirt-clients libguestfs-rescue \
  guestfish guestfs-tools amd64-microcode vivid parted nano python3-json5 \
  nvme-cli cpuinfo smartmontools bash-completion rsyslog proxmox-firewall \
  build-essential screen mtr ruby snmp snmpd starship zram-tools \
  fzf ripgrep jq dnsutils rsync software-properties-common gnupg \
  tmux fonts-powerline fonts-font-awesome yamllint

# ==============================================================
# 3. .bashrc (hyper-focused version)
# ==============================================================
echo "3. Installing .bashrc"
cd /root
cp .bashrc .bashrc.bak 2>/dev/null || true
wget -qO- https://github.com/hyper-focused/proxmox9-init/raw/refs/heads/main/bashrc > .bashrc

# ==============================================================
# 4. NVM + Direnv (required by .bashrc)
# ==============================================================
echo "4. Installing NVM & Direnv"
[ -d ~/.nvm ] || git clone https://github.com/nvm-sh/nvm.git ~/.nvm
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh" && nvm install --lts || true

mkdir -p ~/.local/share
[ -d ~/.local/share/direnv ] || git clone https://github.com/direnv/direnv.git ~/.local/share/direnv
(cd ~/.local/share/direnv && make install) || true

# ==============================================================
# 5. batcat theme
# ==============================================================
echo "5. Configuring batcat"
batcat --generate-config-file
{
  echo '--theme="Monokai Extended"'
  echo '--italic-text=always'
} >> /root/.config/bat/config

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
git clone https://github.com/scopatz/nanorc.git /root/.nano
{
  echo "# nano syntax – auto-generated"
  for f in /root/.nano/*.nanorc; do echo "include \"$f\""; done
} > /root/.nanorc

# ==============================================================
# 9. Hardened SSHD config
# ==============================================================
echo "9. Installing hardened sshd_config"
SSHD="/etc/ssh/sshd_config"
[ -f /etc/ssh/sshd_config.orig ] || cp "$SSHD" /etc/ssh/sshd_config.orig
wget -qO "$SSHD.new" https://github.com/hyper-focused/proxmox9-init/raw/refs/heads/main/sshd_config
sshd -t -f "$SSHD.new" && mv "$SSHD.new" "$SSHD" && systemctl reload sshd
echo "SSHD config applied and reloaded"

# ==============================================================
# DONE
# ==============================================================
echo "=== ALL DONE $(date) ==="
echo "Log: $LOGFILE"
echo "Now run:  source ~/.bashrc"
echo "Open a NEW terminal to see Starship + Nerd Font + tmux + nano syntax"
