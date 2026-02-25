# rails-api

## コマンド

### RuboCop（静的解析）

```bash
# 全ファイルチェック
docker compose exec rails-api bundle exec rubocop

# 自動修正
docker compose exec rails-api bundle exec rubocop -A

# 特定ファイルのみ
docker compose exec rails-api bundle exec rubocop <container_path>
```

`<container_path>` はコンテナ内パス（例: `/app/app/models/claude_collector/session.rb`）。

### RSpec（テスト）

```bash
# 全テスト実行
docker compose exec rails-api bundle exec rspec

# 特定ファイルのみ
docker compose exec rails-api bundle exec rspec <container_path>
```

### Rails Console

```bash
docker compose exec rails-api bin/rails console
```

### DB マイグレーション

```bash
# マイグレーション実行
docker compose exec rails-api bin/rails db:migrate

# DB作成
docker compose exec rails-api bin/rails db:create
```
