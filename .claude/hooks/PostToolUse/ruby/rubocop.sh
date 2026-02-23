#!/bin/bash

# PostToolUse hook: Ruby ファイル編集時に docker compose exec 経由で RuboCop を実行

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common.sh"

readonly DOCKER_SERVICE="claude-collector"

# stdin から JSON を読み取り
if [ -t 0 ]; then
  exit 0
fi

stdin_data=$(cat)

# ファイルパスを抽出
file_path=$(extract_file_path_from_json "$stdin_data") || exit 0

# .rb ファイルでなければスキップ
[[ "$file_path" == *.rb ]] || exit 0

# claude-collector 配下のファイルか判定
[[ "$file_path" == *apps/claude-collector/* ]] || exit 0

# コンテナ内パスを算出（apps/claude-collector/ 以降を /app/ に変換）
container_path="/app/${file_path#*apps/claude-collector/}"

# コンテナが起動しているか確認
if ! docker compose ps --status running "$DOCKER_SERVICE" --quiet 2>/dev/null | grep -q .; then
  exit 0
fi

# rubocop -A で自動修正
docker compose exec -T "$DOCKER_SERVICE" \
  bundle exec rubocop -A --format quiet "$container_path" > /dev/null 2>&1

# 自動修正後に残った違反を確認
result=$(docker compose exec -T "$DOCKER_SERVICE" \
  bundle exec rubocop --format simple "$container_path" 2>&1)
exit_code=$?

if [ $exit_code -ne 0 ]; then
  output_block_decision "RuboCop violations (not auto-correctable) in $file_path:

$result"
fi

exit 0
