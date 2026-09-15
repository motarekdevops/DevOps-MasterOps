#!/usr/bin/env bash
source "$MASTEROPS_HOME/cli/lib/common.sh"

ACTION=""
for arg in "$@"; do
  case "$arg" in
    --start) ACTION="start" ;;
    *) mops_die "unknown flag: $arg" ;;
  esac
done

[[ -z "$ACTION" ]] && mops_die "usage: masterops terraform --start"

# --- Safety check 1: refuse to run on a live AWS server. Real EC2
# instances can reach the AWS instance metadata service at this fixed
# link-local address; a personal laptop cannot. ---
mops_log "checking this isn't running on a live AWS server..."
if curl -s -m 2 http://169.254.169.254/latest/meta-data/ > /dev/null 2>&1; then
  mops_die "AWS metadata service detected -- this looks like an EC2 server, not your laptop. 'masterops terraform --start' must be run from your local machine, before any server exists."
fi
mops_ok "no AWS metadata service detected"

# --- Safety check 2: explicit manual confirmation ---
mops_log "this will download Terraform modules (VPC, EC2, IAM, S3, Route53...) into ./terraform in your current directory."
mops_log "this step provisions real AWS infrastructure once you run 'terraform apply' -- make sure you are on your local machine, not a server."
if ! mops_confirm "continue?"; then
  mops_die "cancelled."
fi

# --- Copy the Terraform module tree into the project ---
TF_SRC="$MASTEROPS_HOME/terraform"
TF_DEST="./terraform"

if [[ -d "$TF_DEST" ]]; then
  mops_die "./terraform already exists in this directory -- refusing to overwrite. Remove or rename it first if you want a fresh copy."
fi

mops_log "copying Terraform modules into $TF_DEST ..."
cp -r "$TF_SRC" "$TF_DEST"
cp "$TF_DEST/terraform.tfvars.example" "$TF_DEST/terraform.tfvars"
mops_ok "Terraform modules ready in $TF_DEST"

mops_log "next steps:"
mops_log "  1. cd terraform"
mops_log "  2. edit terraform.tfvars with your values (region, domain, instance size, etc.)"
mops_log "  3. terraform init"
mops_log "  4. terraform plan"
mops_log "  5. terraform apply"
mops_log "once apply finishes, note the public IP from the output, SSH into the new server, and run:"
mops_log "  sudo apt install masterops -y"
mops_log "to continue setup on the server itself (Nginx, Docker, app stacks)."
