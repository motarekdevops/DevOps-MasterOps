#!/usr/bin/env bash
source "$MASTEROPS_HOME/cli/lib/common.sh"

ACTION=""
for arg in "$@"; do
  case "$arg" in
    --start) ACTION="start" ;;
    *) mops_die "unknown flag: $arg" ;;
  esac
done

[[ -z "$ACTION" ]] && mops_die "usage: masterops nginx --start"

SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"

BACKEND_CONF_NAME="backend.conf"
FRONTEND_CONF_NAME="frontend.conf"

# --- 1. Create Nginx config files (fixed template -- engineer fills in
# the domain and file name placeholders manually afterwards) ---
mops_log "creating Nginx config files from template..."

sudo tee "$SITES_AVAILABLE/$BACKEND_CONF_NAME" > /dev/null << 'CONFEOF'
server {
    listen 80;
    server_name (Enter Your Website Domain  *.Enter Your Website Domain);

    root /var/www/"FILE NAME"/Public;
    index index.php;
}
CONFEOF
mops_ok "wrote: $SITES_AVAILABLE/$BACKEND_CONF_NAME"

sudo tee "$SITES_AVAILABLE/$FRONTEND_CONF_NAME" > /dev/null << 'CONFEOF'
server {
    listen 80;
    server_name (Enter Your Website Domain  *.Enter Your Website Domain);

    root /var/www/"FILE NAME"/Public;
    index index.php;
}
CONFEOF
mops_ok "wrote: $SITES_AVAILABLE/$FRONTEND_CONF_NAME"

mops_log "edit both files now and replace the placeholders before continuing:"
mops_log "  $SITES_AVAILABLE/$BACKEND_CONF_NAME"
mops_log "  $SITES_AVAILABLE/$FRONTEND_CONF_NAME"
read -rp "Press Enter once you've finished editing both config files... " _

# --- 2. Link the conf files into sites-enabled ---
mops_log "linking config files into sites-enabled..."
sudo ln -sf "$SITES_AVAILABLE/$BACKEND_CONF_NAME" "$SITES_ENABLED/$BACKEND_CONF_NAME"
sudo ln -sf "$SITES_AVAILABLE/$FRONTEND_CONF_NAME" "$SITES_ENABLED/$FRONTEND_CONF_NAME"
mops_ok "linked both configs into $SITES_ENABLED"

# --- 3. Test the config files ---
mops_log "testing Nginx configuration..."
if ! sudo nginx -t; then
  mops_die "nginx config test failed -- check the error above before reloading"
fi
mops_ok "nginx config test passed"

# --- 4. Reload Nginx ---
mops_log "reloading Nginx..."
sudo systemctl restart nginx
mops_ok "nginx reloaded"

# --- 5. Create SSL certificate (optional) ---
if mops_confirm "Do you want to add an SSL certificate now using certbot?"; then
  read -rp "Enter the domain for the certificate: " DOMAIN
  [[ -z "$DOMAIN" ]] && mops_die "domain cannot be empty"

  if ! mops_command_exists certbot; then
    mops_log "certbot not found, installing..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
  fi
  sudo certbot --nginx -d "$DOMAIN"
else
  mops_log "skipped certbot."
fi

# --- 6. Fix permissions on /var/www/ ---
mops_log "fixing permissions on /var/www/..."
sudo usermod -a -G www-data "$(whoami)"
sudo chgrp -R www-data /var/www/
sudo chmod -R 775 /var/www/
sudo find /var/www/ -type d -exec chmod g+s {} \;
mops_ok "permissions updated on /var/www/"

mops_ok "nginx setup complete"
mops_log "note: log out and back in for the www-data group membership to take effect"
