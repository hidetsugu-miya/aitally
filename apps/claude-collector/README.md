# claude-collector

`~/.claude.json` を定期的に解析し、Claude Code の利用データ（コスト・トークン使用量・セッション情報）を収集・抽出するツール。

## 概要

Claude Code が `~/.claude.json` に記録するプロジェクト別・モデル別の利用統計を解析し、構造化されたデータとして出力する。

### 収集対象データ

- プロジェクト別の利用コスト (`lastCost`)
- モデル別トークン使用量 (`lastModelUsage`)
  - input / output / cache read / cache creation tokens
  - モデル別コスト (costUSD)
- セッション情報（duration, lines added/removed）
- Web検索リクエスト数

## 技術スタック

- Ruby
- PostgreSQL 17（モノレポ共有インスタンス）

## ディレクトリ構成

```text
apps/claude-collector/
```

## セットアップ

```bash
# PostgreSQL 起動（モノレポルートで）
docker compose up -d

# 依存関係インストール
cd apps/claude-collector
bundle install
```

### データベース接続

モノレポルートの Docker Compose で起動する共有 PostgreSQL に接続する。

```text
postgresql://aitally:aitally@localhost:5433/aitally_claude_collector_development
```

## モノレポ内の位置づけ

[aitally](../../) モノレポの一部として、LLM利用データの収集レイヤーを担当する。

```text
aitally/
  apps/
    claude-collector/  <- このアプリ（Claude Code利用データ収集）
```
