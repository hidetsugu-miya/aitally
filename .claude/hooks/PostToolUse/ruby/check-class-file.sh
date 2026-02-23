#!/bin/bash

# Claude Code ポストタスクフックスクリプト
# このスクリプトは.rbファイルで以下のチェックを行います:
# 1. instance_variable_setの使用が検出された場合に適切なアクセサメソッドの使用を促す
# 2. instance_variable_getの使用が検出された場合に適切なアクセサメソッドの使用を促す
# 3. app/models配下でdefault_scopeの使用が検出された場合に警告を表示（絶対禁止）
# 4. YARD形式の@paramや@returnが検出された場合にrbs-inline形式への移行を促す
# 5. rbs-inline形式で`untyped`の使用が検出された場合に具体的な型への変更を促す

# ============================================================
# 共通ライブラリ読み込み
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh"

# ============================================================
# 設定
# ============================================================

# 定数定義
readonly LOG_FILE="tmp/claude/hook/check_class_file.log"

# プリコンパイル正規表現（高速化 - set/get統合）
readonly PATTERN_INSTANCE_VARIABLE='instance_variable_(set|get)\s*\('
readonly PATTERN_DEFAULT_SCOPE='default_scope\s*(\{|do)'
readonly PATTERN_YARD_TYPE_ANNOTATION='#\s*@(param|return)\s+'
readonly PATTERN_RBS_UNTYPED='#\s*@rbs\s+.*untyped'

# ============================================================
# バリデーター（高速化版）
# ============================================================

# instance_variable_*メソッドの使用をチェック（統合版・高速化）
check_instance_variable_methods() {
    local content="$1"

    if echo "$content" | grep -qE "$PATTERN_INSTANCE_VARIABLE"; then
        return 0
    else
        return 1
    fi
}

# 検出されたinstance_variable_*メソッドの詳細を取得
get_instance_variable_methods_details() {
    local content="$1"

    echo "$content" | grep -nE "$PATTERN_INSTANCE_VARIABLE" | head -5 | sed 's/^\([0-9]*\):/行 \1: /'
}

# default_scopeの使用をチェック
check_default_scope() {
    local content="$1"

    if echo "$content" | grep -qE "$PATTERN_DEFAULT_SCOPE"; then
        return 0
    else
        return 1
    fi
}

# 検出されたdefault_scopeの詳細を取得
get_default_scope_details() {
    local content="$1"

    echo "$content" | grep -nE "$PATTERN_DEFAULT_SCOPE" | head -5 | sed 's/^\([0-9]*\):/行 \1: /'
}

# YARD形式の型注釈（@param/@return）の使用をチェック
check_yard_type_annotations() {
    local content="$1"

    if echo "$content" | grep -qE "$PATTERN_YARD_TYPE_ANNOTATION"; then
        return 0
    else
        return 1
    fi
}

# 検出されたYARD形式型注釈の詳細を取得
get_yard_type_annotations_details() {
    local content="$1"

    echo "$content" | grep -nE "$PATTERN_YARD_TYPE_ANNOTATION" | head -5 | sed 's/^\([0-9]*\):/行 \1: /'
}

# rbs-inline形式でuntypedの使用をチェック
check_rbs_untyped() {
    local content="$1"

    if echo "$content" | grep -qE "$PATTERN_RBS_UNTYPED"; then
        return 0
    else
        return 1
    fi
}

# 検出されたrbs-inline untyped使用の詳細を取得
get_rbs_untyped_details() {
    local content="$1"

    echo "$content" | grep -nE "$PATTERN_RBS_UNTYPED" | head -5 | sed 's/^\([0-9]*\):/行 \1: /'
}

# ============================================================
# フォーマッター
# ============================================================

generate_instance_variable_error_message() {
    local instance_variable_details="$1"
    echo "【禁止】instance_variable_set/get検出。アクセサメソッドに変更必須。検出: $instance_variable_details"
}

generate_default_scope_error_message() {
    local default_scope_details="$1"
    echo "【絶対禁止】default_scope検出。明示的なscopeに変更必須。検出: $default_scope_details"
}

generate_yard_type_annotation_error_message() {
    local yard_details="$1"
    echo "【禁止】YARD形式(@param/@return)検出。rbs-inline形式に変更必須。検出: $yard_details"
}

generate_rbs_untyped_error_message() {
    local untyped_details="$1"
    echo "【禁止】rbs-inlineでuntyped検出。具体的な型に変更必須。検出: $untyped_details"
}

# ============================================================
# メイン処理
# ============================================================

format_multiple_errors() {
    local -a errors=("$@")
    local IFS=$'\n'
    echo "${errors[*]}"
}

perform_all_checks() {
    local content="$1"
    local ruby_file="$2"
    local -a errors=()

    log_debug "$LOG_FILE" "Starting all checks for: $ruby_file"

    # チェック1: instance_variable_set/get（全Rubyファイル）
    if check_instance_variable_methods "$content"; then
        log_debug "$LOG_FILE" "Found instance_variable_set/get"
        errors+=("$(generate_instance_variable_error_message "$(get_instance_variable_methods_details "$content")")")
    fi

    # チェック2: default_scope（app/models配下のみ）
    if [[ "$ruby_file" == */app/models/*.rb ]] || [[ "$ruby_file" == app/models/*.rb ]]; then
        log_debug "$LOG_FILE" "Model file detected, checking default_scope"
        if check_default_scope "$content"; then
            log_debug "$LOG_FILE" "Found default_scope"
            errors+=("$(generate_default_scope_error_message "$(get_default_scope_details "$content")")")
        fi
    fi

    # チェック3: YARD形式型注釈（全Rubyファイル）
    if check_yard_type_annotations "$content"; then
        log_debug "$LOG_FILE" "Found YARD type annotations"
        errors+=("$(generate_yard_type_annotation_error_message "$(get_yard_type_annotations_details "$content")")")
    fi

    # チェック4: rbs-inline untyped（全Rubyファイル）
    if check_rbs_untyped "$content"; then
        log_debug "$LOG_FILE" "Found rbs-inline untyped"
        errors+=("$(generate_rbs_untyped_error_message "$(get_rbs_untyped_details "$content")")")
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

main_check_class_file() {
    execute_hook_template_fast \
        "$LOG_FILE" \
        "*.rb" \
        "perform_all_checks" \
        "Ruby file"
    # exit 0 + stdout JSON で decision 制御
    return 0
}

# ============================================================
# 実行
# ============================================================

main_check_class_file "$@"
