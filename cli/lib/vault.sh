#!/usr/bin/env bash
# MasterOps Vault Utilities
# Handles encryption and decryption of sensitive project secrets.

# Secret key should be stored in a secure location (e.g., /etc/masterops/vault.key)
VAULT_KEY_FILE="/etc/masterops/vault.key"

mops_vault_init() {
  if [[ ! -f "$VAULT_KEY_FILE" ]]; then
    mops_log "Generating master vault key..."
    sudo mkdir -p /etc/masterops
    openssl rand -base64 32 | sudo tee "$VAULT_KEY_FILE" > /dev/null
    sudo chmod 600 "$VAULT_KEY_FILE"
    mops_ok "Vault key generated at $VAULT_KEY_FILE"
  fi
}

mops_vault_set() {
  local project_dir="$1"
  local key_val="$2"
  local vault_file="$project_dir/.env.vault"
  local tmp_env="/tmp/mops_tmp_env"

  # 1. Decrypt existing vault to tmp file
  if [[ -f "$vault_file" ]]; then
    openssl enc -aes-256-cbc -d -salt -pbkdf2 -pass "file:$VAULT_KEY_FILE" -in "$vault_file" > "$tmp_env" 2>/dev/null || touch "$tmp_env"
  else
    touch "$tmp_env"
  fi

  # 2. Update or add the key
  # Remove existing key if it exists, then append new one
  sed -i "/^${key_val%%=*}=/d" "$tmp_env"
  echo "$key_val" >> "$tmp_env"

  # 3. Encrypt back to vault
  openssl enc -aes-256-cbc -salt -pbkdf2 -pass "file:$VAULT_KEY_FILE" -in "$tmp_env" -out "$vault_file"
  sudo chmod 600 "$vault_file"
  rm "$tmp_env"
}

mops_vault_decrypt() {
  local project_dir="$1"
  local vault_file="$project_dir/.env.vault"
  local env_file="$project_dir/.env"

  if [[ ! -f "$vault_file" ]]; then
    mops_error "Vault file not found at $vault_file"
    return 1
  fi

  # Decrypt the content into the .env file
  openssl enc -aes-256-cbc -d -salt -pbkdf2 -pass "file:$VAULT_KEY_FILE" -in "$vault_file" > "$env_file"

  if [[ $? -eq 0 ]]; then
    mops_ok "Vault decrypted into $env_file"
    return 0
  else
    mops_error "Failed to decrypt vault."
    return 1
  fi
}
