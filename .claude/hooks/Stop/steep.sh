#!/bin/bash

# Claude Code Stopフック - Steep型チェック
# Claude応答終了時に実行され、PostToolUseで記録された変更ファイルに対してSteep型チェックを行う。
# エラーがあればblockしてClaudeに修正を促す。
#
# 高速化:
# - PostToolUseでrbs-inlineは実行済み → steep checkのみ直接実行
# - steep_queueに記録された変更ファイルをアプリごとに分類し、各appのDockerコンテナで実行

# ============================================================
# 共通ライブラリ読み込み
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ============================================================
# 定数定義
# ============================================================

readonly LOG_FILE="tmp/claude/hook/steep.log"
readonly STEEP_QUEUE_FILE="tmp/claude/steep_queue"
readonly COMPOSE="docker compose"

# ============================================================
# ターゲットファイル管理
# ============================================================

# steep_queueからチェック対象ファイル一覧を取得
# 戻り値: 0=対象あり（ファイル一覧をstdoutに出力）, 1=対象なし
get_target_files() {
    local project_root="$1"
    local targets_file="$project_root/${STEEP_QUEUE_FILE}"

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

# steep_queueをクリア
clear_target_files() {
    local project_root="$1"
    local targets_file="$project_root/${STEEP_QUEUE_FILE}"

    rm -f "$targets_file"
}

# ============================================================
# Docker実行
# ============================================================

# アプリごとにsteep checkをDocker経由で実行
# steep_queueのファイルをアプリ別に分類し、各appコンテナで実行
run_steep_check() {
    local project_root="$1"
    local target_files="$2"

    local all_output=""
    local final_exit_code=0

    # アプリごとにファイルを分類
    local cc_files=""
    local rails_files=""

    while IFS= read -r file; do
        case "$file" in
            apps/claude-collector/*)
                local rel="${file#apps/claude-collector/}"
                cc_files="${cc_files:+$cc_files }$rel"
                ;;
            apps/rails/*)
                local rel="${file#apps/rails/}"
                rails_files="${rails_files:+$rails_files }$rel"
                ;;
        esac
    done <<< "$target_files"

    # claude-collector
    if [ -n "$cc_files" ]; then
        local compose_file="$project_root/apps/claude-collector/docker-compose.yml"
        local output
        if $COMPOSE -f "$compose_file" ps --status running --format '{{.Name}}' 2>/dev/null | grep -q .; then
            output=$($COMPOSE -f "$compose_file" exec -T app bundle exec steep check $cc_files 2>&1)
        else
            output=$($COMPOSE -f "$compose_file" run --rm app bundle exec steep check $cc_files 2>&1)
        fi
        local ec=$?
        [ $ec -ne 0 ] && final_exit_code=$ec
        all_output="${all_output}${output}"$'\n'
    fi

    # rails
    if [ -n "$rails_files" ]; then
        local compose_file="$project_root/apps/rails/docker-compose.yml"
        local output
        if $COMPOSE -f "$compose_file" ps --status running --format '{{.Name}}' 2>/dev/null | grep -q .; then
            output=$($COMPOSE -f "$compose_file" exec -T app bundle exec steep check $rails_files 2>&1)
        else
            output=$($COMPOSE -f "$compose_file" run --rm app bundle exec steep check $rails_files 2>&1)
        fi
        local ec=$?
        [ $ec -ne 0 ] && final_exit_code=$ec
        all_output="${all_output}${output}"$'\n'
    fi

    echo "$all_output"
    return $final_exit_code
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

    # ターゲットファイルを取得
    local target_files
    target_files=$(get_target_files "$project_root")
    if [ $? -ne 0 ] || [ -z "$target_files" ]; then
        log_debug "$LOG_FILE" "No target files in steep_queue - skipping"
        clear_target_files "$project_root"
        log_debug "$LOG_FILE" "Stop Hook End - No target files"
        exit 0
    fi

    local file_count
    file_count=$(echo "$target_files" | wc -l | tr -d ' ')
    log_debug "$LOG_FILE" "Target files ($file_count): $target_files"

    # Steep実行（アプリごとにDocker経由で実行）
    log_debug "$LOG_FILE" "Running steep check on $file_count file(s) via Docker"
    local steep_output
    local steep_exit_code
    steep_output=$(run_steep_check "$project_root" "$target_files")
    steep_exit_code=$?

    log_debug "$LOG_FILE" "Steep exit code: $steep_exit_code"

    # ターゲットファイルをクリア（成功・失敗問わず）
    clear_target_files "$project_root"

    # 成功時は終了
    if [ $steep_exit_code -eq 0 ]; then
        log_debug "$LOG_FILE" "Stop Hook End - No type errors"
        exit 0
    fi

    # エラーを抽出
    local errors
    errors=$(parse_steep_errors "$steep_output")

    if [ -z "$errors" ]; then
        log_debug "$LOG_FILE" "Steep failed but no type errors found in output"
        local message="Steep型チェックが失敗しました（exit code: $steep_exit_code）。make steep の出力を確認してください。"
        output_block_decision "$message"
        log_debug "$LOG_FILE" "Stop Hook End - Blocked with errors"
        exit 1
    fi

    local error_count
    error_count=$(echo "$errors" | wc -l | tr -d ' ')
    log_debug "$LOG_FILE" "Type errors found: $error_count"

    local all_errors="Steep型エラー ${error_count}件:
${errors}"
    output_block_decision "$all_errors"
    log_debug "$LOG_FILE" "Stop Hook End - Blocked with errors"
    exit 1
}

main "$@"
