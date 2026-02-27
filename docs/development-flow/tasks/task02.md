# タスク2: RspecSetup

## 対象機能

FUNC-002: rspec 基盤構築

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-001: テストフレームワークの導入

## 種別

Config Task

## 概要

apps/rails に rspec-rails を導入し、テスト実行環境を整備する。既存の Minitest 構成（test/ ディレクトリ、rails/test_unit/railtie）を廃止する

## 対象コンポーネント

- Gemfile（パス: `apps/rails/Gemfile`、責務: rspec-rails gem の追加、種別: 修正）
- application.rb（パス: `apps/rails/config/application.rb`、責務: `rails/test_unit/railtie` の require 除去、種別: 修正）
- .rspec（パス: `apps/rails/.rspec`、責務: rspec コマンドラインオプション設定、種別: 新規）
- spec_helper.rb（パス: `apps/rails/spec/spec_helper.rb`、責務: rspec 全体設定、種別: 新規）
- rails_helper.rb（パス: `apps/rails/spec/rails_helper.rb`、責務: Rails 環境での rspec 設定、種別: 新規）

## 利用するコンポーネント

なし

## 実装内容

- `Gemfile` の `:development, :test` グループに `rspec-rails` を追加する
- `config/application.rb` から `require "rails/test_unit/railtie"` を除去する
- `test/` ディレクトリを廃止する（ファイルを削除する）
- `.rspec` ファイルを作成する（`--format documentation`, `--color` 等の設定）
- `spec/spec_helper.rb` を作成する（rspec の基本設定）
- `spec/rails_helper.rb` を作成する（Rails 環境での設定）

## 依存タスク

なし

## 完了条件

- `docker compose exec rails-api bundle exec rspec` コマンドが実行できること
- `spec/` ディレクトリ構成が整備されていること
- `config/application.rb` の変更が完了していること
- `Gemfile` に rspec-rails が追加されていること

## 実行履歴

### 実行1

#### implementer
- ステータス: 完了
- 概要: rspec-rails/simplecov導入、spec_helper.rb/rails_helper.rb作成、test/削除、Makefile更新、モデルテスト3ファイル作成（SimpleCovフィルタ追加含む）

#### CI
- 結果: PASS
- 実行方法: make ci

#### MustFix修正
- 修正対象: MF-1（readonly!未実装）、MF-2（readonly!テスト欠落）、MF-3（describe命名不整合）、MF-4（部分一致検証）
- CI再検証: PASS
