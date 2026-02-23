# claude-collector

## コマンド

### RuboCop（静的解析）

```bash
# 全ファイルチェック
docker compose exec claude-collector bundle exec rubocop

# 自動修正
docker compose exec claude-collector bundle exec rubocop -A

# 特定ファイルのみ
docker compose exec claude-collector bundle exec rubocop <container_path>
```

`<container_path>` はコンテナ内パス（例: `/app/lib/claude_collector/parser.rb`）。

### RSpec（テスト）

```bash
# 全テスト実行
docker compose exec claude-collector bundle exec rspec

# 特定ファイルのみ
docker compose exec claude-collector bundle exec rspec <container_path>
```
