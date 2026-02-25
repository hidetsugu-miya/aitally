# claude-collector

Dockerコンテナ上で動作する。すべてのコマンド（rubocop, rspec, steep, rbs-inline等）はDocker経由で実行すること。

## コマンド

### Make（推奨）

```bash
# appディレクトリから
cd apps/claude-collector
make ci          # rubocop + rspec + steep
make rspec       # テストのみ
make up          # コンテナ起動
make down        # コンテナ停止

# ルートから
make rubocop.claude-collector
make rspec.claude-collector
make steep.claude-collector
```

### RuboCop（静的解析）- Docker実行

```bash
# appディレクトリから
cd apps/claude-collector
make rubocop

# 直接実行
docker compose run --rm app bundle exec rubocop
```

### RSpec（テスト）- Docker実行

```bash
# appディレクトリから
cd apps/claude-collector
docker compose exec app bundle exec rspec

# 特定ファイルのみ
docker compose exec app bundle exec rspec <container_path>
```

`<container_path>` はコンテナ内パス（例: `/app/spec/lib/claude_collector/parser_spec.rb`）。

### RBS Collection（型定義インストール）- Docker実行

```bash
# ルートから実行（全app一括）
make rbs-collection

# appディレクトリから
cd apps/claude-collector
make rbs-collection
```

### rbs-inline（RBS型定義生成）- Docker実行

```bash
# ルートから実行（全app一括）
make rbs-inline

# appディレクトリから
cd apps/claude-collector
make rbs-inline
```

生成されたRBSファイルは `sig/generated/` に出力される。

### Steep（型チェック）- Docker実行

```bash
# ルートから実行（全app一括）
make steep

# appディレクトリから
cd apps/claude-collector
make steep
```
