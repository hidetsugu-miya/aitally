# タスク3: SimplecovSetup

## 対象機能

FUNC-003: simplecov 導入

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-002: コードカバレッジ計測の導入

## 種別

Config Task

## 概要

テスト実行時にコードカバレッジを計測し、レポートを生成する。minimum_coverage 100 を設定し、カバレッジ 100% 未満でテスト失敗とする

## 対象コンポーネント

- Gemfile（パス: `apps/rails/Gemfile`、責務: simplecov gem の追加、種別: 修正）
- spec/spec_helper.rb（パス: `apps/rails/spec/spec_helper.rb`、責務: SimpleCov 起動設定の追加、種別: 修正）
- .gitignore（パス: `apps/rails/.gitignore`、責務: coverage/ ディレクトリの除外設定追加、種別: 修正）

## 利用するコンポーネント

- **依存タスク**: タスク2で作成される spec/spec_helper.rb（パス: `apps/rails/spec/spec_helper.rb`、責務: rspec 全体設定）

## 実装内容

- `Gemfile` の `:test` グループに `simplecov` を追加する
- `spec/spec_helper.rb` の先頭に SimpleCov 起動設定を追加する（`SimpleCov.start 'rails'`）
- `SimpleCov.minimum_coverage 100` を設定する
- `.gitignore` に `coverage/` を追加する

## 依存タスク

タスク 2（RspecSetup）

## 完了条件

- `docker compose exec rails-api bundle exec rspec` 実行後に `coverage/` ディレクトリが生成されること
- カバレッジが 100% 未満の場合にテストが失敗すること
