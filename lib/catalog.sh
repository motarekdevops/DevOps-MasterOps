#!/usr/bin/env bash
# Static catalog of available languages/frameworks per layer.
# Used only in interactive mode (no --preset given).

# Prompts for backend language + framework, returns stack path
# e.g. "backend/php/laravel" or "" if skipped.
choose_backend_stack() {
    local lang
    lang=$(select_option "Choose a backend language:" \
        "PHP" "Python" "Node.js" "Choose later")

    case "$lang" in
        "PHP")
            local fw
            fw=$(select_option "Choose a PHP framework:" "Laravel" "Symfony" "Choose later")
            case "$fw" in
                "Laravel") echo "backend/php/laravel" ;;
                "Symfony") echo "backend/php/symfony" ;;
                *) echo "" ;;
            esac
            ;;
        "Python")
            local fw
            fw=$(select_option "Choose a Python framework:" "Django" "FastAPI" "Flask" "Choose later")
            case "$fw" in
                "Django")  echo "backend/python/django" ;;
                "FastAPI") echo "backend/python/fastapi" ;;
                "Flask")   echo "backend/python/flask" ;;
                *) echo "" ;;
            esac
            ;;
        "Node.js")
            local fw
            fw=$(select_option "Choose a Node.js framework:" "Express" "NestJS" "Choose later")
            case "$fw" in
                "Express") echo "backend/nodejs/express" ;;
                "NestJS")  echo "backend/nodejs/nestjs" ;;
                *) echo "" ;;
            esac
            ;;
        *) echo "" ;;
    esac
}

choose_frontend_stack() {
    local fw
    fw=$(select_option "Choose a frontend framework:" "React" "Vue" "Choose later")
    case "$fw" in
        "React") echo "frontend/reactjs" ;;
        "Vue")   echo "frontend/vue" ;;
        *) echo "" ;;
    esac
}

choose_webserver_stack() {
    local fw
    fw=$(select_option "Choose a web server:" "Nginx" "Apache" "Choose later")
    case "$fw" in
        "Nginx")  echo "webserver/nginx" ;;
        "Apache") echo "webserver/apache" ;;
        *) echo "" ;;
    esac
}

choose_database_stack() {
    local db
    db=$(select_option "Choose a database engine:" "PostgreSQL" "MySQL" "Choose later")
    case "$db" in
        "PostgreSQL") echo "database/postgres" ;;
        "MySQL")      echo "database/mysql" ;;
        *) echo "" ;;
    esac
}
