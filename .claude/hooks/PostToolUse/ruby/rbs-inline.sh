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
readonly STEEP_TARGETS_FILE="tmp/claude/steep_queue"
readonly DOCKER_SERVICE="claude-collector"
readonly RBS_INLINE_CMD="bundle exec rbs-inline --output"

# ============================================================
# パーサー
# ============================================================

# JSON入力からlib/配下のRubyファイルパスを解析
parse_target_ruby_file() {
    local stdin_data="$1"

    local file_path
    file_path=$(extract_file_path_from_json "$stdin_data")
    [ $? -ne 0 ] && return 1

    # .rbファイルのみ対象
    [[ "$file_path" == *.rb ]] || return 1

    # claude-collector配下のファイルか判定
    [[ "$file_path" == *apps/claude-collector/* ]] || return 1

    # コンテナ内パスに変換（apps/claude-collector/ 以降を取得）
    local container_path="${file_path#*apps/claude-collector/}"

    # lib/ 配下のみ対象
    [[ "$container_path" == lib/* ]] || return 1

    echo "$container_path"
    return 0
}

# ============================================================
# Docker実行
# ============================================================

# rbs-inlineを実行（変更ファイルのみ対象）
run_rbs_inline() {
    local project_root="$1"
    local target_file="$2"

    local docker_cmd="docker compose exec -T ${DOCKER_SERVICE}"

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

    local target_file
    target_file=$(parse_target_ruby_file "$stdin_data")
    if [ $? -ne 0 ] || [ -z "$target_file" ]; then
        log_debug "$LOG_FILE" "Not a target file - skipping"
        return 0
    fi

    # コンテナが起動しているか確認
    if ! docker compose ps --status running "$DOCKER_SERVICE" --quiet 2>/dev/null | grep -q .; then
        log_debug "$LOG_FILE" "Container not running - skipping"
        return 0
    fi

    log_debug "$LOG_FILE" "Target file: $target_file"

    # rbs-inline実行
    log_debug "$LOG_FILE" "Running rbs-inline"
    local rbs_output
    rbs_output=$(run_rbs_inline "$project_root" "$target_file")
    local rbs_exit_code=$?
    log_debug "$LOG_FILE" "rbs-inline exit code: $rbs_exit_code"

    # steep_queueにファイルパスを記録（重複排除）
    local targets_file="$project_root/$STEEP_TARGETS_FILE"
    mkdir -p "$(dirname "$targets_file")"

    if ! grep -qxF "$target_file" "$targets_file" 2>/dev/null; then
        echo "$target_file" >> "$targets_file"
        log_debug "$LOG_FILE" "Recorded target: $target_file"
    else
        log_debug "$LOG_FILE" "Target already recorded: $target_file"
    fi

    log_debug "$LOG_FILE" "Hook End"
    return 0
}

main "$@"
