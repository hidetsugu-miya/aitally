#!/bin/bash

# PostToolUse hook: Ruby ファイル編集時に各appのDockerコンテナでRuboCopを実行

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh"

readonly COMPOSE="docker compose"

# stdin から JSON を読み取り
if [ -t 0 ]; then
  exit 0
fi

stdin_data=$(cat)

# ファイルパスを抽出
file_path=$(extract_file_path_from_json "$stdin_data") || exit 0

# .rb ファイルでなければスキップ
[[ "$file_path" == *.rb ]] || exit 0

# apps/ 配下の .rb ファイルのみ対象・compose_dir解決
case "$file_path" in
    apps/claude-collector/*) compose_dir="apps/claude-collector"; rel_path="${file_path#apps/claude-collector/}" ;;
    apps/rails/*)            compose_dir="apps/rails";            rel_path="${file_path#apps/rails/}" ;;
    *) exit 0 ;;
esac

# プロジェクトルートに移動
project_root=$(find_project_root) || exit 0
compose_file="$project_root/$compose_dir/docker-compose.yml"

# Docker compose コマンド選択（起動中ならexec、未起動ならrun）
if $COMPOSE -f "$compose_file" ps --status running --format '{{.Name}}' 2>/dev/null | grep -q .; then
    run_cmd="$COMPOSE -f $compose_file exec -T app"
else
    run_cmd="$COMPOSE -f $compose_file run --rm app"
fi

# rubocop -A で自動修正
$run_cmd bundle exec rubocop -A --format quiet "$rel_path" > /dev/null 2>&1

# 自動修正後に残った違反を確認
result=$($run_cmd bundle exec rubocop --format simple "$rel_path" 2>&1)
exit_code=$?

if [ $exit_code -ne 0 ]; then
  output_block_decision "RuboCop violations (not auto-correctable) in $file_path:

$result"
fi

exit 0
