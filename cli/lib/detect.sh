#!/usr/bin/env bash

detect_framework() {
  local dir="$1"
  if [[ -f "$dir/composer.json" ]]; then
    grep -q "laravel/framework" "$dir/composer.json" 2>/dev/null && { echo "Laravel"; return; }
    grep -q "symfony/symfony"   "$dir/composer.json" 2>/dev/null && { echo "Symfony"; return; }
    echo "PHP"; return
  fi
  if [[ -f "$dir/manage.py" ]]; then echo "Django"; return; fi
  if [[ -f "$dir/requirements.txt" ]]; then
    grep -qi "flask"     "$dir/requirements.txt" 2>/dev/null && { echo "Flask"; return; }
    grep -qi "fastapi"   "$dir/requirements.txt" 2>/dev/null && { echo "FastAPI"; return; }
    grep -qi "django"    "$dir/requirements.txt" 2>/dev/null && { echo "Django"; return; }
    echo "Python"; return
  fi
  if [[ -f "$dir/package.json" ]]; then
    grep -q '"next"'     "$dir/package.json" 2>/dev/null && { echo "Next.js"; return; }
    grep -q '"nuxt"'     "$dir/package.json" 2>/dev/null && { echo "Nuxt"; return; }
    grep -q '"vue"'      "$dir/package.json" 2>/dev/null && { echo "Vue"; return; }
    grep -q '"react"'    "$dir/package.json" 2>/dev/null && { echo "React"; return; }
    grep -q '"express"'  "$dir/package.json" 2>/dev/null && { echo "Express"; return; }
    grep -q '"@nestjs'   "$dir/package.json" 2>/dev/null && { echo "NestJS"; return; }
    echo "Node.js"; return
  fi
  if [[ -f "$dir/go.mod" ]]; then echo "Go"; return; fi
  if [[ -f "$dir/Gemfile" ]]; then
    grep -qi "rails" "$dir/Gemfile" 2>/dev/null && { echo "Rails"; return; }
    echo "Ruby"; return
  fi
  if [[ -f "$dir/Cargo.toml" ]]; then echo "Rust"; return; fi
  if [[ -f "$dir/index.html" ]]; then echo "Static HTML"; return; fi
  echo "unknown"
}

detect_db_type() {
  local deploy_name="$1" deploy_type="$2"
  local engine="unknown"

  case "$deploy_type" in
    container)
      local image
      image="$(docker inspect --format '{{.Config.Image}}' "$deploy_name" 2>/dev/null || echo "")"
      case "$image" in
        postgres*) engine="PostgreSQL" ;;
        mysql*)    engine="MySQL" ;;
        mariadb*)  engine="MariaDB" ;;
        mongo*)    engine="MongoDB" ;;
        redis*)    engine="Redis" ;;
        "")        engine="unknown (container not found)" ;;
        *)         engine="$image" ;;
      esac
      ;;
    native)
      if systemctl is-active --quiet postgresql 2>/dev/null; then engine="PostgreSQL"
      elif systemctl is-active --quiet mysql 2>/dev/null; then engine="MySQL"
      elif systemctl is-active --quiet mariadb 2>/dev/null; then engine="MariaDB"
      elif systemctl is-active --quiet mongod 2>/dev/null; then engine="MongoDB"
      elif systemctl is-active --quiet redis-server 2>/dev/null; then engine="Redis"
      fi
      ;;
  esac

  echo "$engine"
}

detect_github() {
  local dir="$1"
  if [[ -d "$dir/.git" ]]; then
    local remote branch
    remote="$(git -C "$dir" config --get remote.origin.url 2>/dev/null || echo "")"
    branch="$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")"
    if [[ -n "$remote" ]]; then
      echo "$remote (branch: $branch)"
    else
      echo "local repo, no remote"
    fi
  else
    echo "not a git repo"
  fi
}
