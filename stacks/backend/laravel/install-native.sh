#!/usr/bin/env bash
# Native install for a Laravel (PHP-FPM) backend on the host server (no container).
set -e

echo "[masterops] Installing PHP-FPM and required extensions natively..."
sudo apt update
sudo apt install -y php-fpm php-cli php-common php-mbstring php-xml php-bcmath \
    php-curl php-zip php-pgsql php-mysql unzip curl

PHP_FPM_SERVICE=$(systemctl list-unit-files --type=service 2>/dev/null | grep -oP 'php[0-9.]+-fpm\.service' | head -n1)
if [[ -z "$PHP_FPM_SERVICE" ]]; then
  echo "[masterops] WARNING: could not detect a php-fpm service unit. Enable it manually, e.g.: sudo systemctl enable --now php8.3-fpm"
else
  sudo systemctl enable --now "$PHP_FPM_SERVICE"
  echo "[masterops] enabled and started: $PHP_FPM_SERVICE"
fi

if ! command -v composer &> /dev/null; then
  echo "[masterops] Installing Composer..."
  curl -sS https://getcomposer.org/installer | php
  sudo mv composer.phar /usr/local/bin/composer
fi

echo "[masterops] PHP version: $(php -v | head -n1)"
echo "[masterops] Composer version: $(composer --version)"

if [[ -f "./backend/composer.json" ]]; then
  echo "[masterops] Running composer install in ./backend ..."
  (cd ./backend && composer install --no-interaction --prefer-dist)
else
  echo "[masterops] No composer.json found in ./backend yet -- skipping composer install."
  echo "[masterops] Once your Laravel code is in ./backend, run: cd backend && composer install"
fi

echo "[masterops] Laravel native install complete."
echo "[masterops] PHP-FPM is listening on its default socket/port -- point your Nginx"
echo "[masterops] server block at it (see: masterops nginx --start)."
