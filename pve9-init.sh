# ... [All previous sections unchanged] ...

# Configure Starship Terminal
echo "=== Configuring Starship Terminal ==="
mkdir -p ~/.config
[ -f ~/.config/starship.toml ] && cp ~/.config/starship.toml ~/.config/starship.toml.bak || true
wget --spider https://github.com/smithumble/starship-cockpit/raw/refs/heads/main/starship.toml 2>/dev/null || { echo "ERROR: starship.toml URL unreachable"; exit 1; }
wget -O ~/.config/starship.toml https://github.com/smithumble/starship-cockpit/raw/refs/heads/main/starship.toml || { echo "ERROR: starship.toml download failed"; exit 1; }
echo "Starship configured."

# === Install SSHD Hardened Config ===
echo "=== Installing Custom SSHD Config ==="
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_BACKUP="/etc/ssh/sshd_config.orig"
SSHD_URL="https://github.com/hyper-focused/proxmox9-init/raw/refs/heads/main/sshd_config"

# Backup current config (idempotent)
if [ ! -f "$SSHD_BACKUP" ]; then
    cp "$SSHD_CONFIG" "$SSHD_BACKUP" && echo "Backed up $SSHD_CONFIG → $SSHD_BACKUP"
else
    echo "Backup already exists: $SSHD_BACKUP"
fi

# Download new config
if ! wget --spider "$SSHD_URL" 2>/dev/null; then
    echo "ERROR: SSHD config URL unreachable: $SSHD_URL"
    exit 1
fi
if ! wget -O "$SSHD_CONFIG.new" "$SSHD_URL"; then
    echo "ERROR: Failed to download SSHD config"
    rm -f "$SSHD_CONFIG.new"
    exit 1
fi

# Validate syntax
if ! sshd -t -f "$SSHD_CONFIG.new" > /dev/null 2>&1; then
    echo "ERROR: New sshd_config has syntax errors:"
    sshd -t -f "$SSHD_CONFIG.new"
    rm -f "$SSHD_CONFIG.new"
    exit 1
fi

# Apply new config
mv "$SSHD_CONFIG.new" "$SSHD_CONFIG" && echo "Applied new sshd_config"

# Reload SSHD
if systemctl reload sshd; then
    echo "SSHD reloaded successfully"
else
    echo "ERROR: Failed to reload sshd – check logs with: journalctl -u sshd"
    echo "You can revert with: cp $SSHD_BACKUP $SSHD_CONFIG && systemctl reload sshd"
    exit 1
fi

# Final sanity check: confirm sshd is active and listening
if systemctl is-active --quiet sshd && ss -tlnp | grep -q sshd; then
    echo "SSHD is running and listening on configured ports"
else
    echo "WARNING: SSHD may not be fully operational – verify with 'ss -tlnp | grep sshd'"
fi

echo "SSHD config updated and verified."

# === End of Script ===
echo "Proxmox Init Script completed at $(date). Log: $LOGFILE"
echo "Run 'source ~/.bashrc' and open a new terminal to see changes."
