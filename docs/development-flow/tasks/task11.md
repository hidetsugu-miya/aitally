# タスク11: ClaudeCollector::ModelUsageResource

## 対象機能

FUNC-008: セッション詳細 API

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-006: セッション詳細の参照API

## 種別

Feature Task

## 概要

モデル別利用量を JSON にシリアライズする Resource クラスを alba で実装する。全カラム（id, session_id, model_id, input_tokens, output_tokens 等）を含む。セッション詳細 API とモデル別利用量一覧 API の両方で利用される

## 対象コンポーネント

- ClaudeCollector::ModelUsageResource（パス: `apps/rails/app/resources/claude_collector/model_usage_resource.rb`、責務: モデル別利用量の JSON シリアライズ定義（全カラムを含む）、種別: 新規）

## 利用するコンポーネント

- **既存**: ClaudeCollector::ModelUsage（パス: `apps/rails/app/models/claude_collector/model_usage.rb`、責務: モデル別利用量情報モデル）
- **依存タスク**: タスク 5 で作成される alba 設定（`app/resources/` ディレクトリ）

## 実装内容

- `app/resources/claude_collector/model_usage_resource.rb` に `ClaudeCollector::ModelUsageResource` を作成する（`include Alba::Resource`）
- モデル別利用量の全カラムを attributes に定義する
- `spec/resources/claude_collector/model_usage_resource_spec.rb` を作成しテストする

## 依存タスク

タスク 5（AlbaSetup）

## 完了条件

- `spec/resources/claude_collector/model_usage_resource_spec.rb` のテストがパスすること
