#!/bin/bash

# PostToolUse hook: Ruby ファイル編集時に docker compose exec 経由で RuboCop を実行

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh"

# stdin から JSON を読み取り
if [ -t 0 ]; then
  exit 0
fi

stdin_data=$(cat)

# ファイルパスを抽出
file_path=$(extract_file_path_from_json "$stdin_data") || exit 0

# .rb ファイルでなければスキップ
[[ "$file_path" == *.rb ]] || exit 0

# Docker サービスを判定
docker_service=$(resolve_docker_service "$file_path") || exit 0

# コンテナ内パスを算出
container_path=$(resolve_container_path "$file_path") || exit 0

# コンテナが起動しているか確認
if ! docker compose ps --status running "$docker_service" --quiet 2>/dev/null | grep -q .; then
  exit 0
fi

# rubocop -A で自動修正
docker compose exec -T "$docker_service" \
  bundle exec rubocop -A --format quiet "$container_path" > /dev/null 2>&1

# 自動修正後に残った違反を確認
result=$(docker compose exec -T "$docker_service" \
  bundle exec rubocop --format simple "$container_path" 2>&1)
exit_code=$?

if [ $exit_code -ne 0 ]; then
  output_block_decision "RuboCop violations (not auto-correctable) in $file_path:

$result"
fi

exit 0
