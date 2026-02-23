#!/bin/bash

# Claude Code SessionStartフック - claude-collectorコンテナ自動起動
# セッション開始時にコンテナを起動し、フックでdocker compose execを使用可能にする。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

readonly LOG_FILE="tmp/claude/hook/docker-app.log"
readonly DOCKER_SERVICE="claude-collector"

main() {
    local project_root
    if ! project_root=$(find_project_root) || [ -z "$project_root" ]; then
        exit 0
    fi

    setup_log_directory "$LOG_FILE"
    log_debug "$LOG_FILE" "SessionStart Hook Start"

    # コンテナが既に起動中か確認
    local status
    status=$(cd "$project_root" && docker compose ps --format '{{.Service}} {{.State}}' 2>/dev/null | grep "^${DOCKER_SERVICE} " | awk '{print $2}')

    if [[ "$status" == "running" ]]; then
        log_debug "$LOG_FILE" "claude-collector container already running"
    else
        log_debug "$LOG_FILE" "Starting claude-collector container"
        cd "$project_root" && docker compose up -d "$DOCKER_SERVICE" 2>&1 | while read -r line; do
            log_debug "$LOG_FILE" "docker: $line"
        done
    fi

    log_debug "$LOG_FILE" "SessionStart Hook End"
}

main "$@"
