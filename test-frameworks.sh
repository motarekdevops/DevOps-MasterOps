#!/usr/bin/env bash
set -e

# Define test projects
# Format: "name|backend|frontend|db|mode|web|domain|k8s"
PROJECTS=(
  "test-django|django|vue|postgres|native|nginx|django-test.com|false"
  "test-spring|springboot|nextjs|mysql|native|nginx|spring-test.com|false"
  "test-go|go|svelte|redis|native|nginx|go-test.com|false"
  "test-dotnet|dotnet|angular|postgres|native|nginx|dotnet-test.com|false"
)

echo "Starting MasterOps Framework Validation Suite..."
echo "===================================================="

for proj in "${PROJECTS[@]}"; do
  IFS='|' read -r name backend frontend db mode web domain k8s <<< "$proj"
  
  echo "Testing: $name ($backend + $frontend)"
  
  # Mapping names to numbers for the wizard
  B_NUM=1; [[ "$backend" == "dotnet" ]] && B_NUM=2; [[ "$backend" == "springboot" ]] && B_NUM=3; [[ "$backend" == "go" ]] && B_NUM=4; [[ "$backend" == "django" ]] && B_NUM=5
  F_NUM=1; [[ "$frontend" == "vue" ]] && F_NUM=2; [[ "$frontend" == "nextjs" ]] && F_NUM=3; [[ "$frontend" == "svelte" ]] && F_NUM=4; [[ "$frontend" == "angular" ]] && F_NUM=5
  D_NUM=1; [[ "$db" == "mysql" ]] && D_NUM=2; [[ "$db" == "mariadb" ]] && D_NUM=3; [[ "$db" == "redis" ]] && D_NUM=4
  M_NUM=1; [[ "$mode" == "native" ]] && M_NUM=2
  W_NUM=1; [[ "$web" == "apache" ]] && W_NUM=2

  INPUTS="$B_NUM\n$F_NUM\n$D_NUM\n$M_NUM\n$W_NUM\n$domain\n$k8s\ny\n"
  
  echo -e "$INPUTS" | masterops start "$name"
  
  if [ $? -eq 0 ]; then
    echo -e "\n[SUCCESS] $name provisioned successfully.\n"
  else
    echo -e "\n[FAILED] $name failed to provision.\n"
  fi
done

echo "===================================================="
echo "Validation Suite Complete."
echo "Run 'masterops status' to see the final results."
