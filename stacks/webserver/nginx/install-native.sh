#!/usr/bin/env bash
# Native install for Nginx on the host server (no container).
set -e

source "$MASTEROPS_HOME/lib/port_check.sh"

echo "[masterops] Installing Nginx natively..."
sudo apt update

# Block apt from auto-starting/enabling the service during install (Debian
# policy triggers this on package setup). We control start/enable ourselves
# below, based on whether port 80 is actually free.
sudo tee /usr/sbin/policy-rc.d > /dev/null << 'POLICYEOF'
#!/bin/sh
exit 101
POLICYEOF
sudo chmod +x /usr/sbin/policy-rc.d

sudo apt install -y nginx

sudo rm -f /usr/sbin/policy-rc.d

if check_port_free 80 "Nginx"; then
    sudo systemctl enable --now nginx
    echo "[masterops] Nginx native install complete."
    echo "[masterops] Config path: /etc/nginx/sites-available/"
else
    echo "[masterops] Nginx installed but NOT started/enabled -- port 80 is occupied."
    echo "[masterops] Free the port, then run: sudo systemctl enable --now nginx"
fi
