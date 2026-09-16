#!/usr/bin/env bash
set -e

# Define test projects
PROJECTS=(
  "django|vue|postgres|native|nginx|django-test.com|false"
  "springboot|nextjs|mysql|native|nginx|spring-test.com|false"
  "go|svelte|redis|native|nginx|go-test.com|false"
  "dotnet|angular|postgres|native|nginx|dotnet-test.com|false"
)

echo "Starting MasterOps Framework Validation Suite (Random Names)..."
echo "===================================================="

# Clean up logs first
sudo rm -f /tmp/masterops_ansible.log

for proj in "${PROJECTS[@]}"; do
  # Generate random project name to avoid collision
  RAND_NAME="val-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)"
  
  IFS='|' read -r backend frontend db mode web domain k8s <<< "$proj"
  
  echo "Testing: $RAND_NAME ($backend + $frontend)"
  
  B_NUM=1; [[ "$backend" == "dotnet" ]] && B_NUM=2; [[ "$backend" == "springboot" ]] && B_NUM=3; [[ "$backend" == "go" ]] && B_NUM=4; [[ "$backend" == "django" ]] && B_NUM=5
  F_NUM=1; [[ "$frontend" == "vue" ]] && F_NUM=2; [[ "$frontend" == "nextjs" ]] && F_NUM=3; [[ "$frontend" == "svelte" ]] && F_NUM=4; [[ "$frontend" == "angular" ]] && F_NUM=5
  D_NUM=1; [[ "$db" == "mysql" ]] && D_NUM=2; [[ "$db" == "mariadb" ]] && D_NUM=3; [[ "$db" == "redis" ]] && D_NUM=4
  M_NUM=1; [[ "$mode" == "native" ]] && M_NUM=2
  W_NUM=1; [[ "$web" == "apache" ]] && W_NUM=2

  INPUTS="$B_NUM\n$F_NUM\n$D_NUM\n$M_NUM\n$W_NUM\n$domain\n$k8s\ny\n"
  
  # We run masterops start as sudo.
  echo -e "$INPUTS" | sudo masterops start "$RAND_NAME"
  
  if [ $? -eq 0 ]; then
    echo -e "\n[SUCCESS] $RAND_NAME provisioned successfully.\n"
  else
    echo -e "\n[FAILED] $RAND_NAME failed to provision.\n"
  fi
done

echo "===================================================="
echo "Validation Suite Complete."
echo "Run 'masterops status' to see the final results."
