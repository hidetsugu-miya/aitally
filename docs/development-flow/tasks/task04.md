# タスク 4: RswagSetup

## 対象機能

FUNC-004: rswag 導入

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-003: APIドキュメント生成の導入

## 種別

Config Task

## 概要

rspec の request spec から OpenAPI 仕様のドキュメントを生成し、ブラウザで閲覧可能にする。API-only モードでの動作を確認し、必要に応じてミドルウェア設定を追加する。

## 対象コンポーネント

- Gemfile（パス: `apps/rails/Gemfile`、責務: rswag-specs, rswag-api, rswag-ui gem の追加、種別: 修正）
- swagger_helper.rb（パス: `apps/rails/spec/swagger_helper.rb`、責務: OpenAPI 仕様の基本設定（タイトル、バージョン、サーバー情報）、種別: 新規）
- routes.rb（パス: `apps/rails/config/routes.rb`、責務: Swagger UI のマウントパス追加、種別: 修正）

## 利用するコンポーネント

- **依存タスク**: タスク 2 で作成される `rails_helper.rb`（パス: `apps/rails/spec/rails_helper.rb`、責務: Rails 環境での rspec 設定）

## 実装内容

- `Gemfile` に `rswag-specs`, `rswag-api`, `rswag-ui` を追加する（rswag-specs は test グループ）
- `spec/swagger_helper.rb` を作成する（OpenAPI 仕様の基本情報、タイトル: "aitally API"、バージョン: "v1"）
- `config/routes.rb` に Swagger UI のマウントパスを追加する（`mount Rswag::Ui::Engine => '/api-docs'`, `mount Rswag::Api::Engine => '/api-docs'`）
- API-only モードでの rswag 動作を確認し、`action_view/railtie` が既に require 済みであることを確認する

## 依存タスク

タスク 2（RspecSetup）

## 完了条件

- `rake rswag:specs:swaggerize` でドキュメント生成が実行できること
- `swagger/v1/swagger.yaml`（または同等のファイル）が生成されること
