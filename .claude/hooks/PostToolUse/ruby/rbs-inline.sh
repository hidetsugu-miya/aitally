#!/bin/bash

# Claude Code PostToolUseフック - rbs-inline
# .rbファイル編集時にrbs-inlineを実行してRBS型定義を最新化し、
# 変更ファイルパスをsteep_queueに記録する（Stopフックで使用）

# ============================================================
# 共通ライブラリ読み込み
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh"

# ============================================================
# 定数定義
# ============================================================

readonly LOG_FILE="tmp/claude/hook/rbs-inline.log"
readonly STEEP_QUEUE_PREFIX="tmp/claude/steep_queue"
readonly RBS_INLINE_CMD="bundle exec rbs-inline --output"

# ============================================================
# パーサー
# ============================================================

# JSON入力から対象Rubyファイルのコンテナ内パスを解析
# 出力: コンテナ内パス（例: lib/foo.rb, app/models/bar.rb）
# 戻り値: 0=対象, 1=非対象
parse_target_ruby_file() {
    local stdin_data="$1"

    local file_path
    file_path=$(extract_file_path_from_json "$stdin_data")
    [ $? -ne 0 ] && return 1

    # .rbファイルのみ対象
    [[ "$file_path" == *.rb ]] || return 1

    # Dockerサービスを判定
    local service
    service=$(resolve_docker_service "$file_path") || return 1

    # コンテナ内パスに変換
    local container_path
    case "$service" in
        claude-collector) container_path="${file_path#*apps/claude-collector/}" ;;
        rails-api)        container_path="${file_path#*apps/rails/}" ;;
        *)                return 1 ;;
    esac

    # rbs-inline対象ディレクトリを判定
    case "$service" in
        claude-collector)
            [[ "$container_path" == lib/* ]] || return 1
            ;;
        rails-api)
            [[ "$container_path" == app/* || "$container_path" == lib/* ]] || return 1
            ;;
    esac

    echo "${service}|${container_path}"
    return 0
}

# ============================================================
# Docker実行
# ============================================================

# rbs-inlineを実行（変更ファイルのみ対象）
run_rbs_inline() {
    local project_root="$1"
    local service="$2"
    local target_file="$3"

    local docker_cmd="docker compose exec -T ${service}"

    cd "$project_root" && $docker_cmd $RBS_INLINE_CMD "$target_file" 2>&1
}

# ============================================================
# メイン処理
# ============================================================

main() {
    local project_root
    project_root=$(find_project_root)
    if [ $? -ne 0 ] || [ -z "$project_root" ]; then
        return 0
    fi

    setup_log_directory "$LOG_FILE"
    log_debug "$LOG_FILE" "Hook Start"

    # 標準入力からファイルパスを取得
    if [ -t 0 ]; then
        log_debug "$LOG_FILE" "No stdin input"
        return 0
    fi

    local stdin_data
    stdin_data=$(cat)

    local parsed
    parsed=$(parse_target_ruby_file "$stdin_data")
    if [ $? -ne 0 ] || [ -z "$parsed" ]; then
        log_debug "$LOG_FILE" "Not a target file - skipping"
        return 0
    fi

    local service="${parsed%%|*}"
    local target_file="${parsed#*|}"

    # コンテナが起動しているか確認
    if ! docker compose ps --status running "$service" --quiet 2>/dev/null | grep -q .; then
        log_debug "$LOG_FILE" "Container not running ($service) - skipping"
        return 0
    fi

    log_debug "$LOG_FILE" "Service: $service, Target file: $target_file"

    # rbs-inline実行
    log_debug "$LOG_FILE" "Running rbs-inline"
    local rbs_output
    rbs_output=$(run_rbs_inline "$project_root" "$service" "$target_file")
    local rbs_exit_code=$?
    log_debug "$LOG_FILE" "rbs-inline exit code: $rbs_exit_code"

    # steep_queue.{service}にファイルパスを記録（重複排除）
    local targets_file="$project_root/${STEEP_QUEUE_PREFIX}.${service}"
    mkdir -p "$(dirname "$targets_file")"

    if ! grep -qxF "$target_file" "$targets_file" 2>/dev/null; then
        echo "$target_file" >> "$targets_file"
        log_debug "$LOG_FILE" "Recorded target: $target_file (queue: $targets_file)"
    else
        log_debug "$LOG_FILE" "Target already recorded: $target_file"
    fi

    log_debug "$LOG_FILE" "Hook End"
    return 0
}

main "$@"
