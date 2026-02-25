#!/bin/bash

# Claude Code フック共通ライブラリ
# 全てのフックスクリプトで共通して使用される関数群

# ============================================================
# パス・文字列操作
# ============================================================

# プロジェクトルート（aitally）を検出する関数
find_project_root() {
    local current_dir="$PWD"

    # パターン1: 現在のディレクトリにdocker-compose.ymlがある
    if [[ -f "$current_dir/docker-compose.yml" ]]; then
        echo "$current_dir"
        return 0
    fi

    # 見つからない場合
    return 1
}

# 絶対パスを相対パスに変換
to_relative_path() {
    local path="$1"
    echo "${path#"$PWD/"}"
}

# JSON用に文字列をエスケープ
json_escape() {
    local text="$1"
    printf '%s' "$text" | jq -Rs .
}

# ============================================================
# コマンド可用性チェック
# ============================================================

check_jq_available() {
    if ! command -v jq &> /dev/null; then
        return 1
    fi
    return 0
}

# ============================================================
# Docker Compose ディレクトリ解決
# ============================================================

# ファイルパスからapp内docker-composeディレクトリを解決
resolve_compose_dir() {
    local file_path="$1"
    local project_root="$2"
    case "$file_path" in
        *apps/claude-collector/*) echo "$project_root/apps/claude-collector" ;;
        *apps/rails/*)            echo "$project_root/apps/rails" ;;
        *)                        return 1 ;;
    esac
}

# ============================================================
# Docker パス解決
# ============================================================

# ファイルパスからコンテナ内パスを算出
resolve_container_path() {
    local file_path="$1"

    case "$file_path" in
        *apps/claude-collector/*) echo "/app/${file_path#*apps/claude-collector/}" ;;
        *apps/rails/*)            echo "/app/${file_path#*apps/rails/}" ;;
        *)                        return 1 ;;
    esac
}

# ============================================================
# JSON解析
# ============================================================

extract_file_path_from_json() {
    local stdin_data="$1"

    if ! check_jq_available; then
        return 1
    fi

    local file_path
    file_path=$(echo "$stdin_data" | jq -r '.tool_input.file_path // .tool_input.relative_path // empty' 2>/dev/null)

    [ -z "$file_path" ] && return 1

    to_relative_path "$file_path"
    return 0
}

# ============================================================
# ログ管理
# ============================================================

setup_log_directory() {
    local log_file="$1"
    mkdir -p "$(dirname "$log_file")"
}

log_debug() {
    local log_file="$1"
    local message="$2"

    echo "$(date +%H:%M:%S) $message" >> "$log_file"
}

# ============================================================
# Claude Code出力
# ============================================================

output_block_decision() {
    local message="$1"
    local escaped_message
    escaped_message=$(json_escape "$message")

    cat << EOF
{
  "decision": "block",
  "reason": $escaped_message
}
EOF
}

# ============================================================
# JSON解析（拡張）
# ============================================================

# JSON入力からcontentまたはnew_stringを抽出する共通関数
extract_content_from_json() {
    local stdin_data="$1"

    if ! check_jq_available; then
        return 1
    fi

    echo "$stdin_data" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null
}

# 高速JSON解析（複数値を一度に取得）
# 戻り値: file_path|content の形式で返す
extract_file_and_content_fast() {
    local stdin_data="$1"

    if ! check_jq_available; then
        return 1
    fi

    local result
    result=$(echo "$stdin_data" | jq -r '
        (.tool_input.file_path // .tool_input.relative_path // "") + "|" +
        (.tool_input.content // .tool_input.new_string // "")
    ' 2>/dev/null)

    if [ -z "$result" ] || [ "$result" == "|" ]; then
        return 1
    fi

    echo "$result"
    return 0
}

# ============================================================
# フック実行テンプレート
# ============================================================

# フック実行テンプレート関数（高速化版）
# 引数:
#   $1: ログファイルパス
#   $2: ファイル拡張子パターン (例: "*_spec.rb")
#   $3: チェック実行関数名
#   $4: ファイル種別名（ログ用）
execute_hook_template_fast() {
    local log_file="$1"
    local file_pattern="$2"
    local check_function="$3"
    local file_type_name="$4"

    local target_file=""
    local content=""

    setup_log_directory "$log_file"
    log_debug "$log_file" "Hook Start"

    if [ ! -t 0 ]; then
        local stdin_data
        stdin_data=$(cat)
        log_debug "$log_file" "Input received"

        local fast_result
        fast_result=$(extract_file_and_content_fast "$stdin_data")
        local parse_result=$?

        if [ $parse_result -eq 0 ] && [ -n "$fast_result" ]; then
            local file_path="${fast_result%%|*}"
            local content="${fast_result#*|}"
            local file_name="${file_path##*/}"

            log_debug "$log_file" "File path: $file_path"
            log_debug "$log_file" "File name: $file_name"
            log_debug "$log_file" "File pattern: $file_pattern"

            if [[ "$file_name" == $file_pattern ]]; then
                target_file=$(to_relative_path "$file_path")

                log_debug "$log_file" "$file_type_name: $target_file"
                log_debug "$log_file" "Content size: ${#content} characters"
                log_debug "$log_file" "Pattern matched: $file_name == $file_pattern"
            else
                log_debug "$log_file" "Pattern not matched: $file_name != $file_pattern"
            fi
        fi
    fi

    if [ -z "$target_file" ] || [ -z "$content" ]; then
        log_debug "$log_file" "Skipping - no target file or content"
        return 0
    fi

    $check_function "$content" "$target_file"
    local result=$?

    if [ $result -eq 0 ]; then
        log_debug "$log_file" "Hook End - All OK"
    else
        log_debug "$log_file" "Hook End - Issues found"
    fi

    return $result
}
