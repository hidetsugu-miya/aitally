#!/bin/bash

# Claude Code PostToolUseフック - rbs-inline
# .rbファイル編集時にrbs-inlineを実行してRBS型定義を最新化し、
# 変更ファイルパスをsteep_queueに記録する（Stopフックで使用）
# 各appのDockerコンテナ内で実行

# ============================================================
# 共通ライブラリ読み込み
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh"

# ============================================================
# 定数定義
# ============================================================

readonly LOG_FILE="tmp/claude/hook/rbs-inline.log"
readonly STEEP_QUEUE_FILE="tmp/claude/steep_queue"
readonly COMPOSE="docker compose"
readonly RBS_INLINE_CMD="bundle exec rbs-inline --output"

# ============================================================
# パーサー
# ============================================================

# JSON入力から対象Rubyファイルのモノレポ相対パスを解析
# 出力: モノレポ相対パス（例: apps/rails/app/models/foo.rb）
# 戻り値: 0=対象, 1=非対象
parse_target_ruby_file() {
    local stdin_data="$1"

    local file_path
    file_path=$(extract_file_path_from_json "$stdin_data")
    [ $? -ne 0 ] && return 1

    # .rbファイルのみ対象
    [[ "$file_path" == *.rb ]] || return 1

    # rbs-inline対象ディレクトリを判定
    case "$file_path" in
        *apps/claude-collector/lib/*) ;;
        *apps/rails/app/*) ;;
        *apps/rails/lib/*) ;;
        *) return 1 ;;
    esac

    echo "$file_path"
    return 0
}

# ============================================================
# Docker実行
# ============================================================

# ファイルパスからアプリディレクトリとアプリ相対パスを解決
# 例: apps/claude-collector/lib/foo.rb → app_dir=apps/claude-collector, rel_path=lib/foo.rb
resolve_app_context() {
    local file_path="$1"

    case "$file_path" in
        apps/claude-collector/*)
            echo "apps/claude-collector"
            echo "${file_path#apps/claude-collector/}"
            ;;
        apps/rails/*)
            echo "apps/rails"
            echo "${file_path#apps/rails/}"
            ;;
        *)
            return 1
            ;;
    esac
}

# rbs-inlineをDocker経由で実行（appコンテナ内でsig/generated/を生成）
run_rbs_inline() {
    local project_root="$1"
    local target_file="$2"

    local app_context
    app_context=$(resolve_app_context "$target_file")
    if [ $? -ne 0 ]; then
        return 1
    fi

    local app_dir
    app_dir=$(echo "$app_context" | head -1)
    local rel_path
    rel_path=$(echo "$app_context" | tail -1)

    local compose_dir="$project_root/$app_dir"

    # コンテナ起動中ならexec（高速）、未起動ならrun --rm
    if $COMPOSE -f "$compose_dir/docker-compose.yml" ps --status running --format '{{.Name}}' 2>/dev/null | grep -q .; then
        $COMPOSE -f "$compose_dir/docker-compose.yml" exec -T app $RBS_INLINE_CMD "$rel_path" 2>&1
    else
        $COMPOSE -f "$compose_dir/docker-compose.yml" run --rm app $RBS_INLINE_CMD "$rel_path" 2>&1
    fi
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

    log_debug "$LOG_FILE" "Target file: $target_file"

    # rbs-inline実行
    log_debug "$LOG_FILE" "Running rbs-inline"
    local rbs_output
    rbs_output=$(run_rbs_inline "$project_root" "$target_file")
    local rbs_exit_code=$?
    log_debug "$LOG_FILE" "rbs-inline exit code: $rbs_exit_code"

    # steep_queueにファイルパスを記録（重複排除）
    local targets_file="$project_root/${STEEP_QUEUE_FILE}"
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
