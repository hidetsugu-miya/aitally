#!/bin/bash

# Claude Code ポストタスクフックスクリプト
# このスクリプトは_spec.rbファイルで以下のチェックを行います:
# 1. MasterXXX || createまたはfind_or_create_by!が使用された場合に修正を促す
# 2. defメソッドが定義された場合にletブロックの使用を促す
# 3. lambda/procが使用された場合に通常のブロック記法への修正を促す
# 4. allow/instance_doubleがmock:start/mock:end範囲外で使用された場合に修正を促す
# 5. rubocop:disableコメントが使用された場合に修正を促す

# ============================================================
# 共通ライブラリ読み込み
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh"

# ============================================================
# 設定
# ============================================================

# 定数定義
readonly LOG_FILE="tmp/claude/hook/check_spec_file.log"

# プリコンパイル正規表現（高速化）
readonly PATTERN_DEF='^\s*def\s+[a-zA-Z_]'
readonly PATTERN_MASTER='Master[A-Z][a-zA-Z]*.*(\|\|\s*create|\.find_or_create_by!?)'
readonly PATTERN_LAMBDA='(\blambda\s*(\{|do)|->[s\(]|\bproc\s*(\{|do)|\bProc\.new\s*(\{|do))'
readonly PATTERN_FORBIDDEN_WORDS='\b(allow|instance_double|define_singleton_method)\b'
readonly PATTERN_RUBOCOP_DISABLE='#\s*rubocop:disable'
readonly PATTERN_COMMENT_FILTER='^[0-9]*:\s*#'
readonly PATTERN_COMMENT_LINE='^\s*#'

# ============================================================
# バリデーター（高速化版）
# ============================================================

check_def_usage() {
    local content="$1"
    echo "$content" | grep -qE "$PATTERN_DEF"
}

get_def_details() {
    local content="$1"
    echo "$content" | grep -nE "$PATTERN_DEF" | head -5 | sed 's/^\([0-9]*\):/行 \1: /'
}

check_lambda_usage() {
    local content="$1"
    local found_lambda=false
    local in_lambda_range=false

    while IFS= read -r line; do
        if echo "$line" | grep -qEi '#.*lambda:start'; then
            in_lambda_range=true
            continue
        fi

        if echo "$line" | grep -qEi '#.*lambda:end'; then
            in_lambda_range=false
            continue
        fi

        if echo "$line" | grep -qE "$PATTERN_LAMBDA"; then
            if ! $in_lambda_range; then
                found_lambda=true
                break
            fi
        fi
    done <<< "$content"

    $found_lambda && return 0 || return 1
}

get_lambda_details() {
    local content="$1"
    local in_lambda_range=false
    local result=""

    while IFS= read -r line_with_num; do
        local line="${line_with_num#*:}"

        if echo "$line" | grep -qEi '#.*lambda:start'; then
            in_lambda_range=true
            continue
        fi

        if echo "$line" | grep -qEi '#.*lambda:end'; then
            in_lambda_range=false
            continue
        fi

        if ! $in_lambda_range && echo "$line" | grep -qE "$PATTERN_LAMBDA"; then
            result="${result}${line_with_num}"$'\n'
        fi
    done < <(echo "$content" | grep -nE "$PATTERN_LAMBDA" | head -5 | sed 's/^\([0-9]*\):/行 \1: /')

    echo "$result"
}

check_master_with_create() {
    local content="$1"
    echo "$content" | grep -E "$PATTERN_MASTER" | grep -qvE "$PATTERN_COMMENT_LINE"
}

get_master_create_details() {
    local content="$1"
    echo "$content" | grep -nE "$PATTERN_MASTER" | grep -vE "$PATTERN_COMMENT_FILTER" | head -5 | sed 's/^\([0-9]*\):/行 \1: /'
}

check_forbidden_words() {
    local content="$1"

    local found_forbidden=false
    local in_mock_range=false

    while IFS= read -r line; do
        if echo "$line" | grep -qEi '#.*mock:start'; then
            in_mock_range=true
            continue
        fi

        if echo "$line" | grep -qEi '#.*mock:end'; then
            in_mock_range=false
            continue
        fi

        if echo "$line" | grep -qE "$PATTERN_FORBIDDEN_WORDS"; then
            if $in_mock_range; then
                continue
            fi

            found_forbidden=true
            break
        fi
    done <<< "$content"

    $found_forbidden && return 0 || return 1
}

check_rubocop_disable() {
    local content="$1"
    echo "$content" | grep -qE "$PATTERN_RUBOCOP_DISABLE"
}

get_rubocop_disable_details() {
    local content="$1"
    echo "$content" | grep -nE "$PATTERN_RUBOCOP_DISABLE" | head -5 | sed 's/^\([0-9]*\):/行 \1: /'
}

# ============================================================
# フォーマッター
# ============================================================

generate_def_error_message() {
    local def_details="$1"
    echo "【禁止】specでdef検出。letブロックに変更必須。検出: $def_details"
}

generate_lambda_error_message() {
    local lambda_details="$1"
    echo "【禁止】specでlambda/proc検出。通常ブロックに変更、またはlambda:start/endで囲むこと。検出: $lambda_details"
}

generate_master_error_message() {
    local master_details="$1"
    echo "【禁止】MasterXXX禁止パターン検出。検出: $master_details"
}

generate_mock_error_message() {
    echo "【禁止】allow/instance_double/define_singleton_method検出。mock:start/endで囲むこと。"
}

generate_rubocop_disable_error_message() {
    local rubocop_details="$1"
    echo "【禁止】rubocop:disable検出。コードを修正してRuboCop警告を解消すること。検出: $rubocop_details"
}

format_multiple_errors() {
    local -a errors=("$@")
    local IFS=$'\n'
    echo "${errors[*]}"
}

# ============================================================
# メイン処理
# ============================================================

perform_all_checks() {
    local content="$1"
    local spec_file="$2"
    local -a errors=()

    log_debug "$LOG_FILE" "Starting all checks for: $spec_file"

    # チェック1: MasterXXX禁止パターン
    if check_master_with_create "$content"; then
        log_debug "$LOG_FILE" "Found prohibited Master pattern"
        errors+=("$(generate_master_error_message "$(get_master_create_details "$content")")")
    fi

    # チェック2: defメソッド定義
    if check_def_usage "$content"; then
        log_debug "$LOG_FILE" "Found def methods"
        errors+=("$(generate_def_error_message "$(get_def_details "$content")")")
    fi

    # チェック3: lambda使用
    if check_lambda_usage "$content"; then
        log_debug "$LOG_FILE" "Found lambda/proc"
        errors+=("$(generate_lambda_error_message "$(get_lambda_details "$content")")")
    fi

    # チェック4: allow/instance_double使用（mock:start/mock:end範囲外）
    if check_forbidden_words "$content"; then
        log_debug "$LOG_FILE" "Found mock usage outside mock:start/mock:end range"
        errors+=("$(generate_mock_error_message)")
    fi

    # チェック5: rubocop:disable使用
    if check_rubocop_disable "$content"; then
        log_debug "$LOG_FILE" "Found rubocop:disable comment"
        errors+=("$(generate_rubocop_disable_error_message "$(get_rubocop_disable_details "$content")")")
    fi

    # エラーが見つかった場合、統合メッセージを生成
    if [ ${#errors[@]} -gt 0 ]; then
        log_debug "$LOG_FILE" "Total errors found: ${#errors[@]}"
        output_block_decision "$(format_multiple_errors "${errors[@]}")"
        return 1
    fi

    log_debug "$LOG_FILE" "All checks passed"
    return 0
}

main_check_spec_file() {
    execute_hook_template_fast \
        "$LOG_FILE" \
        "*_spec.rb" \
        "perform_all_checks" \
        "Spec file"
    # exit 0 + stdout JSON で decision 制御
    return 0
}

# ============================================================
# 実行
# ============================================================

main_check_spec_file "$@"
