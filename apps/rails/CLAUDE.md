# rails-api

Dockerコンテナ上で動作する。すべてのコマンド（rubocop, steep, rbs-inline, brakeman等）はDocker経由で実行すること。

## コマンド

### Make（推奨）

```bash
# appディレクトリから
cd apps/rails
make ci          # rubocop + brakeman + steep
make brakeman    # セキュリティスキャン
make up          # コンテナ起動
make down        # コンテナ停止

# ルートから
make rubocop.rails
make brakeman
make steep.rails
```

### RuboCop（静的解析）- Docker実行

```bash
# appディレクトリから
cd apps/rails
make rubocop

# 直接実行
docker compose run --rm app bundle exec rubocop
```

### Brakeman（セキュリティスキャン）- Docker実行

```bash
# appディレクトリから
cd apps/rails
make brakeman

# 直接実行
docker compose run --rm app bundle exec brakeman --no-pager
```

### RBS Collection（型定義インストール）- Docker実行

```bash
# ルートから実行（全app一括）
make rbs-collection

# appディレクトリから
cd apps/rails
make rbs-collection
```

### rbs-inline（RBS型定義生成）- Docker実行

```bash
# ルートから実行（全app一括）
make rbs-inline

# appディレクトリから
cd apps/rails
make rbs-inline
```

生成されたRBSファイルは `sig/generated/` に出力される。

### Steep（型チェック）- Docker実行

```bash
# ルートから実行（全app一括）
make steep

# appディレクトリから
cd apps/rails
make steep
```

### Rails Console - Docker実行

```bash
cd apps/rails
docker compose exec app bin/rails console
```

### DB マイグレーション - Docker実行

```bash
cd apps/rails

# マイグレーション実行
docker compose exec app bin/rails db:migrate

# DB作成
docker compose exec app bin/rails db:create
```
