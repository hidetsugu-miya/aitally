# aitally

LLM の利用データ（コスト・トークン使用量）を収集・集約するモノレポ。

## apps

| アプリ | 概要 |
|---|---|
| [claude-collector](apps/claude-collector/) | Claude Code の利用データ収集 |

## セットアップ

```bash
cp .env.example .env
docker compose up -d
```

PostgreSQL が `localhost:5433` で起動する。各 app はこの共有インスタンスに接続する。
