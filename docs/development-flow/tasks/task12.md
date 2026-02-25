# タスク12: ClaudeCollector::SessionDetailResource

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

セッション詳細情報をネストした model_usages を含む JSON にシリアライズする Resource クラスを alba で実装する。alba の nested resource（has_many）で model_usages を表現する

## 対象コンポーネント

- ClaudeCollector::SessionDetailResource（パス: `apps/rails/app/resources/claude_collector/session_detail_resource.rb`、責務: セッション詳細（モデル別利用量を含む）の JSON シリアライズ定義、種別: 新規）

## 利用するコンポーネント

- **既存**: ClaudeCollector::Session（パス: `apps/rails/app/models/claude_collector/session.rb`、責務: Claude セッション情報モデル）
- **依存タスク**: タスク 5 で作成される alba 設定（`app/resources/` ディレクトリ）
- **依存タスク**: タスク 11 で作成される ClaudeCollector::ModelUsageResource（パス: `apps/rails/app/resources/claude_collector/model_usage_resource.rb`、責務: モデル別利用量 JSON シリアライズ）

## 実装内容

- `app/resources/claude_collector/session_detail_resource.rb` に `ClaudeCollector::SessionDetailResource` を作成する（`include Alba::Resource`）
- セッションの全カラムを attributes に定義する
- `has_many :model_usages, resource: ClaudeCollector::ModelUsageResource` でネストした model_usages を定義する
- `spec/resources/claude_collector/session_detail_resource_spec.rb` を作成しテストする

## 依存タスク

タスク 5（AlbaSetup）、タスク 11（ModelUsageResource）

## 完了条件

- `spec/resources/claude_collector/session_detail_resource_spec.rb` のテストがパスすること
- シリアライズ結果に `model_usages` 配列が含まれること
