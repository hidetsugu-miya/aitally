#!/bin/bash

# Claude Code SessionStartフック - Docker自動起動
# セッション開始時にpostgresと各appコンテナを起動し、
# フックでdocker compose execを使用可能にする。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

readonly LOG_FILE="tmp/claude/hook/docker-app.log"

# appサービスの起動（個別docker-compose）
start_app_service() {
    local project_root="$1"
    local service="$2"

    local compose_dir
    compose_dir=$(resolve_compose_dir "$service" "$project_root")
    if [ $? -ne 0 ] || [ -z "$compose_dir" ]; then
        log_debug "$LOG_FILE" "Unknown service: $service - skipping"
        return 1
    fi

    # コンテナが既に起動中か確認
    local status
    status=$(cd "$compose_dir" && docker compose ps --format '{{.Service}} {{.State}}' 2>/dev/null | grep "^${service} " | awk '{print $2}')

    if [[ "$status" == "running" ]]; then
        log_debug "$LOG_FILE" "$service container already running"
    else
        log_debug "$LOG_FILE" "Starting $service container"
        cd "$compose_dir" && docker compose up -d 2>&1 | while read -r line; do
            log_debug "$LOG_FILE" "docker ($service): $line"
        done
    fi
}

main() {
    local project_root
    if ! project_root=$(find_project_root) || [ -z "$project_root" ]; then
        exit 0
    fi

    setup_log_directory "$LOG_FILE"
    log_debug "$LOG_FILE" "SessionStart Hook Start"

    # 1. postgres起動（ルートcompose）
    local pg_status
    pg_status=$(cd "$project_root" && docker compose ps --format '{{.Service}} {{.State}}' 2>/dev/null | grep "^postgres " | awk '{print $2}')

    if [[ "$pg_status" == "running" ]]; then
        log_debug "$LOG_FILE" "postgres container already running"
    else
        log_debug "$LOG_FILE" "Starting postgres container"
        cd "$project_root" && docker compose up -d --wait 2>&1 | while read -r line; do
            log_debug "$LOG_FILE" "docker (postgres): $line"
        done
    fi

    # 2. 各appサービス起動
    start_app_service "$project_root" "claude-collector"
    start_app_service "$project_root" "rails-api"

    log_debug "$LOG_FILE" "SessionStart Hook End"
}

main "$@"
