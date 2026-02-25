# タスク 9: ClaudeCollector::SessionResource

## 対象機能

FUNC-007: セッション一覧 API

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-005: セッション一覧の参照API

## 種別

Feature Task

## 概要

セッション情報を JSON にシリアライズする Resource クラスを alba で実装する。全カラム（id, session_id, project_path, cost_usd 等）を含む。

## 対象コンポーネント

- ClaudeCollector::SessionResource（パス: `apps/rails/app/resources/claude_collector/session_resource.rb`、責務: セッションの JSON シリアライズ定義（全カラムを含む）、種別: 新規）

## 利用するコンポーネント

- **既存**: `ClaudeCollector::Session`（パス: `apps/rails/app/models/claude_collector/session.rb`、責務: Claude セッション情報モデル）
- **依存タスク**: タスク 5 で作成される alba 設定（`app/resources/` ディレクトリ）

## 実装内容

- `app/resources/claude_collector/session_resource.rb` に `ClaudeCollector::SessionResource` を作成する（`include Alba::Resource`）
- セッションの全カラムを attributes に定義する
- `spec/resources/claude_collector/session_resource_spec.rb` を作成しテストする

## 依存タスク

タスク 5（AlbaSetup）

## 完了条件

- `spec/resources/claude_collector/session_resource_spec.rb` のテストがパスすること
