# タスク 14: Api::V1::ClaudeCollector::ModelUsagesController

## 対象機能

FUNC-009: モデル別利用量一覧 API

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-007: モデル別利用量一覧の参照API

## 種別

Feature Task

## 概要

モデル別利用量一覧をページネーション付きで取得する `index` アクションを実装する。kaminari でページネーションを適用し、ModelUsageResource でシリアライズ、PaginationMeta でメタ情報を付与する。レスポンス構造: `{ data: [...], meta: { total_count, total_pages, current_page } }`

## 対象コンポーネント

- Api::V1::ClaudeCollector::ModelUsagesController（パス: `apps/rails/app/controllers/api/v1/claude_collector/model_usages_controller.rb`、責務: モデル別利用量一覧の HTTP リクエスト処理、種別: 新規）
- routes.rb（パス: `apps/rails/config/routes.rb`、責務: モデル別利用量一覧エンドポイントのルーティング追加、種別: 修正）

## 利用するコンポーネント

- **既存**: ClaudeCollector::ModelUsage（パス: `apps/rails/app/models/claude_collector/model_usage.rb`、責務: モデル別利用量情報モデル）
- **依存タスク**: タスク 7 で作成される PaginationMeta（パス: `apps/rails/app/presenters/pagination_meta.rb`、責務: ページネーションメタ情報）
- **依存タスク**: タスク 8 で作成される Api::V1::BaseController（パス: `apps/rails/app/controllers/api/v1/base_controller.rb`、責務: 共通基底コントローラ）
- **依存タスク**: タスク 11 で作成される ClaudeCollector::ModelUsageResource（パス: `apps/rails/app/resources/claude_collector/model_usage_resource.rb`、責務: モデル別利用量 JSON シリアライズ）

## 実装内容

- `app/controllers/api/v1/claude_collector/model_usages_controller.rb` に `Api::V1::ClaudeCollector::ModelUsagesController < Api::V1::BaseController` を作成する
- `index` アクションを実装する（`ClaudeCollector::ModelUsage.page(page).per(per)` でページネーション適用）
- `config/routes.rb` の claude_collector 名前空間に `resources :model_usages, only: [:index]` を追加する
- `spec/requests/api/v1/claude_collector/model_usages_spec.rb` に rswag 形式で GET /api/v1/claude_collector/model_usages の request spec を作成する

## 依存タスク

タスク 2（RspecSetup）、タスク 4（RswagSetup）、タスク 7（PaginationMeta）、タスク 8（BaseController）、タスク 11（ModelUsageResource）

## 完了条件

- `spec/requests/api/v1/claude_collector/model_usages_spec.rb` のテストがパスすること
- GET /api/v1/claude_collector/model_usages が `{ data: [...], meta: {...} }` 形式で応答すること
