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

### Brakeman（セキュリティスキャン）

```bash
# 全ファイルチェック
docker compose exec rails-api bundle exec brakeman --no-pager
```

### RSpec（テスト）

```bash
# 全テスト実行
docker compose exec rails-api bundle exec rspec

# 特定ファイルのみ
docker compose exec rails-api bundle exec rspec <container_path>
```

### rbs-inline（RBS型定義生成）

```bash
# app/ からRBS生成
docker compose exec rails-api bundle exec rbs-inline --output app/

# lib/ からRBS生成
docker compose exec rails-api bundle exec rbs-inline --output lib/

# 特定ファイルのみ
docker compose exec rails-api bundle exec rbs-inline --output <container_path>
```

生成されたRBSファイルは `sig/generated/` に出力される。

### Steep（型チェック）

```bash
# 全ファイルチェック
docker compose exec rails-api bundle exec steep check

# 特定ファイルのみ
docker compose exec rails-api bundle exec steep check <container_path>

# 並列実行
docker compose exec rails-api bundle exec steep check --jobs 4
```

### RBS Collection（gem型定義管理）

```bash
# gem型定義のインストール・更新
docker compose exec rails-api bundle exec rbs collection install
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
