# タスク8: Api::V1::BaseController

## 対象機能

FUNC-007: セッション一覧 API

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-005: セッション一覧の参照API

## 種別

Shared Component Task

## 概要

API v1 の共通基底コントローラを作成する。ページネーションパラメータの取得、ActiveRecord::RecordNotFound の rescue_from によるエラーハンドリングを提供する

## 対象コンポーネント

- Api::V1::BaseController（パス: `apps/rails/app/controllers/api/v1/base_controller.rb`、責務: API v1 共通の基底コントローラ（エラーハンドリング、ページネーションパラメータ処理）、種別: 新規）

## 利用するコンポーネント

- **既存**: ApplicationController（パス: `apps/rails/app/controllers/application_controller.rb`、責務: Rails 基底コントローラ）

## 実装内容

- `app/controllers/api/v1/base_controller.rb` に `Api::V1::BaseController < ApplicationController` を作成する
- `pagination_params` メソッドを実装する（`page` と `per` クエリパラメータを取得）
- `rescue_from ActiveRecord::RecordNotFound` で 404 レスポンス `{ error: { code: "not_found", message: "..." } }` を返す処理を実装する
- `spec/requests/api/v1/base_controller_spec.rb` を作成しテストする

## 依存タスク

- タスク 2（RspecSetup）
- タスク 4（RswagSetup）

## 完了条件

- `spec/requests/api/v1/base_controller_spec.rb` のテストがパスすること
- 新規ファイル作成のため影響範囲は狭い
