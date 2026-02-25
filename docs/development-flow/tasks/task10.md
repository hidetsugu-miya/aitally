# タスク10: Api::V1::ClaudeCollector::SessionsController（index）

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

セッション一覧を取得する `index` アクションを実装する。kaminari でページネーションを適用し、SessionResource でシリアライズ、PaginationMeta でメタ情報を付与する。レスポンス構造: `{ data: [...], meta: { total_count, total_pages, current_page } }`

## 対象コンポーネント

- Api::V1::ClaudeCollector::SessionsController（パス: `apps/rails/app/controllers/api/v1/claude_collector/sessions_controller.rb`、責務: セッション一覧・詳細の HTTP リクエスト処理、種別: 新規）
- routes.rb（パス: `apps/rails/config/routes.rb`、責務: セッション一覧・詳細エンドポイントのルーティング追加、種別: 修正）

## 利用するコンポーネント

- **既存**: ClaudeCollector::Session（パス: `apps/rails/app/models/claude_collector/session.rb`、責務: Claude セッション情報モデル）
- **依存タスク**: タスク7で作成される PaginationMeta（パス: `apps/rails/app/presenters/pagination_meta.rb`、責務: ページネーションメタ情報）
- **依存タスク**: タスク8で作成される Api::V1::BaseController（パス: `apps/rails/app/controllers/api/v1/base_controller.rb`、責務: 共通基底コントローラ）
- **依存タスク**: タスク9で作成される ClaudeCollector::SessionResource（パス: `apps/rails/app/resources/claude_collector/session_resource.rb`、責務: セッション JSON シリアライズ）

## 実装内容

- `app/controllers/api/v1/claude_collector/sessions_controller.rb` に `Api::V1::ClaudeCollector::SessionsController < Api::V1::BaseController` を作成する
- `index` アクションを実装する（`ClaudeCollector::Session.page(page).per(per)` でページネーション適用）
- `config/routes.rb` に `namespace :api do namespace :v1 do namespace :claude_collector do resources :sessions, only: [:index, :show] end end end` を追加する
- `spec/requests/api/v1/claude_collector/sessions_spec.rb` に rswag 形式で GET /api/v1/claude_collector/sessions の request spec を作成する

## 依存タスク

- タスク2（RspecSetup）
- タスク4（RswagSetup）
- タスク7（PaginationMeta）
- タスク8（BaseController）
- タスク9（SessionResource）

## 完了条件

- `spec/requests/api/v1/claude_collector/sessions_spec.rb` の index テストがパスすること
- GET /api/v1/claude_collector/sessions が `{ data: [...], meta: {...} }` 形式で応答すること
