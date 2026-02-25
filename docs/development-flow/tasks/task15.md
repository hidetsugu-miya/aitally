# タスク15: ExistingClassesTest

## 対象機能

FUNC-002: rspec 基盤構築
FUNC-003: simplecov 導入

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-001: テストフレームワークの導入
REQ-002: コードカバレッジ計測の導入

## 種別

確認テストタスク

## 概要

コード変更不要だがカバレッジ 100% 達成のためテストが必要な既存クラス（ApplicationController, ApplicationRecord, ClaudeCollectorRecord）のテストを作成する。ClaudeCollector::Session と ClaudeCollector::ModelUsage は各 API タスク（Task 9〜14）のテストでカバーされるため除外。

## 対象コンポーネント

- spec/controllers/application_controller_spec.rb（パス: `apps/rails/spec/controllers/application_controller_spec.rb`、責務: ApplicationController のテスト（コード変更なし）、種別: 新規）
- spec/models/application_record_spec.rb（パス: `apps/rails/spec/models/application_record_spec.rb`、責務: ApplicationRecord のテスト（コード変更なし）、種別: 新規）
- spec/models/claude_collector_record_spec.rb（パス: `apps/rails/spec/models/claude_collector_record_spec.rb`、責務: ClaudeCollectorRecord のテスト（コード変更なし）、種別: 新規）

## 利用するコンポーネント

- **既存**: ApplicationController（パス: `apps/rails/app/controllers/application_controller.rb`、責務: Rails 基底コントローラ）
- **既存**: ApplicationRecord（パス: `apps/rails/app/models/application_record.rb`、責務: Rails 基底モデル）
- **既存**: ClaudeCollectorRecord（パス: `apps/rails/app/models/claude_collector_record.rb`、責務: claude_collector データベース接続の抽象クラス）
- **依存タスク**: タスク 2 で作成される rspec 環境（パス: `apps/rails/spec/`、責務: テスト実行環境）
- **依存タスク**: タスク 3 で設定される simplecov（minimum_coverage 100 達成のため）

## 実装内容

- `spec/controllers/application_controller_spec.rb` を作成する（ApplicationController の基本動作を確認するテスト）
- `spec/models/application_record_spec.rb` を作成する（ApplicationRecord の基本動作を確認するテスト）
- `spec/models/claude_collector_record_spec.rb` を作成する（ClaudeCollectorRecord の基本動作・claude_collector DB への接続を確認するテスト）

## 依存タスク

タスク 2（RspecSetup）、タスク 3（SimplecovSetup）

## 完了条件

- `spec/controllers/application_controller_spec.rb` のテストがパスすること
- `spec/models/application_record_spec.rb` のテストがパスすること
- `spec/models/claude_collector_record_spec.rb` のテストがパスすること
- 全テスト実行時に simplecov のカバレッジ 100% が達成されること
