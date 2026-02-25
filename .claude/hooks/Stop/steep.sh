#!/bin/bash

# Claude Code Stopフック - Steep型チェック
# Claude応答終了時に実行され、PostToolUseで記録された変更ファイルに対してSteep型チェックを行う。
# エラーがあればblockしてClaudeに修正を促す。
#
# 高速化:
# - PostToolUseでrbs-inlineは実行済み → steep checkのみ直接実行
# - steep_queue.{service}に記録された変更ファイルのみチェック（全体スキャン回避）

# ============================================================
# 共通ライブラリ読み込み
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ============================================================
# 定数定義
# ============================================================

readonly LOG_FILE="tmp/claude/hook/steep.log"
readonly STEEP_QUEUE_PREFIX="tmp/claude/steep_queue"
readonly SERVICES=("claude-collector" "rails-api")

# ============================================================
# ターゲットファイル管理
# ============================================================

# steep_queue.{service}からチェック対象ファイル一覧を取得
# 戻り値: 0=対象あり（ファイル一覧をstdoutに出力）, 1=対象なし
get_target_files() {
    local project_root="$1"
    local service="$2"
    local targets_file="$project_root/${STEEP_QUEUE_PREFIX}.${service}"

    if [ ! -f "$targets_file" ]; then
        return 1
    fi

    local targets
    targets=$(cat "$targets_file" 2>/dev/null | sort -u)

    if [ -z "$targets" ]; then
        return 1
    fi

    echo "$targets"
    return 0
}

# steep_queue.{service}をクリア
clear_target_files() {
    local project_root="$1"
    local service="$2"
    local targets_file="$project_root/${STEEP_QUEUE_PREFIX}.${service}"

    rm -f "$targets_file"
}

# ============================================================
# Docker実行
# ============================================================

# 対象ファイルに対してsteep checkを実行
run_steep_check() {
    local project_root="$1"
    local service="$2"
    local target_files="$3"

    local docker_cmd="docker compose exec -T ${service}"

    local steep_output
    local exit_code

    # ファイル一覧をスペース区切りに変換してsteep checkに渡す
    local files_args
    files_args=$(echo "$target_files" | tr '\n' ' ')

    steep_output=$(cd "$project_root" && $docker_cmd bundle exec steep check --jobs 4 $files_args 2>&1)
    exit_code=$?

    echo "$steep_output"
    return $exit_code
}

# ============================================================
# エラー解析
# ============================================================

# Steep出力からエラーを抽出
parse_steep_errors() {
    local steep_output="$1"

    # steep checkの出力からエラー行を抽出
    # 形式: file.rb:line:col: [error] message (DiagnosticCode)
    echo "$steep_output" | grep -E '\.rb:[0-9]+:[0-9]+:.*\[error\]'
}

# ============================================================
# メイン処理
# ============================================================

main() {
    # プロジェクトルートを検出
    local project_root
    if ! project_root=$(find_project_root) || [ -z "$project_root" ]; then
        exit 0
    fi

    setup_log_directory "$LOG_FILE"
    log_debug "$LOG_FILE" "Stop Hook Start"

    local all_errors=""
    local has_errors=false

    for service in "${SERVICES[@]}"; do
        # ターゲットファイルを取得
        local target_files
        target_files=$(get_target_files "$project_root" "$service")
        if [ $? -ne 0 ] || [ -z "$target_files" ]; then
            log_debug "$LOG_FILE" "No target files in steep_queue.$service - skipping"
            clear_target_files "$project_root" "$service"
            continue
        fi

        # コンテナが起動しているか確認
        if ! docker compose ps --status running "$service" --quiet 2>/dev/null | grep -q .; then
            log_debug "$LOG_FILE" "Container not running ($service) - skipping"
            clear_target_files "$project_root" "$service"
            continue
        fi

        local file_count
        file_count=$(echo "$target_files" | wc -l | tr -d ' ')
        log_debug "$LOG_FILE" "[$service] Target files ($file_count): $target_files"

        # Steep実行（対象ファイルのみ）
        log_debug "$LOG_FILE" "[$service] Running steep check on $file_count file(s)"
        local steep_output
        local steep_exit_code
        steep_output=$(run_steep_check "$project_root" "$service" "$target_files")
        steep_exit_code=$?

        log_debug "$LOG_FILE" "[$service] Steep exit code: $steep_exit_code"

        # ターゲットファイルをクリア（成功・失敗問わず）
        clear_target_files "$project_root" "$service"

        # 成功時はスキップ
        if [ $steep_exit_code -eq 0 ]; then
            log_debug "$LOG_FILE" "[$service] No type errors"
            continue
        fi

        # エラーを抽出
        local errors
        errors=$(parse_steep_errors "$steep_output")

        if [ -z "$errors" ]; then
            log_debug "$LOG_FILE" "[$service] Steep failed but no type errors found in output"
            all_errors+="[$service] Steep型チェックが失敗しました（exit code: $steep_exit_code）。docker compose exec $service bundle exec steep check --jobs 4 の出力を確認してください。
"
            has_errors=true
            continue
        fi

        local error_count
        error_count=$(echo "$errors" | wc -l | tr -d ' ')
        log_debug "$LOG_FILE" "[$service] Type errors found: $error_count"

        all_errors+="[$service] Steep型エラー ${error_count}件:
${errors}
"
        has_errors=true
    done

    if [ "$has_errors" = true ]; then
        output_block_decision "$all_errors"
        log_debug "$LOG_FILE" "Stop Hook End - Blocked with errors"
        exit 1
    fi

    log_debug "$LOG_FILE" "Stop Hook End - No type errors"
    exit 0
}

main "$@"
