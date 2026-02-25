# タスク 13: Api::V1::ClaudeCollector::SessionsController（show）

## 対象機能

FUNC-008: セッション詳細 API

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-006: セッション詳細の参照 API

## 種別

Feature Task

## 概要

セッション詳細を取得する `show` アクションを SessionsController に追加する。`session_id` カラムで検索し、SessionDetailResource でシリアライズする。存在しない場合は BaseController の rescue_from で 404 を返す。レスポンス構造: `{ data: { ...session_attributes, model_usages: [...] } }`

## 対象コンポーネント

- Api::V1::ClaudeCollector::SessionsController（パス: `apps/rails/app/controllers/api/v1/claude_collector/sessions_controller.rb`、責務: セッション詳細の show アクション追加、種別: 修正）

## 利用するコンポーネント

- **既存**: ClaudeCollector::Session（パス: `apps/rails/app/models/claude_collector/session.rb`、責務: Claude セッション情報モデル）
- **依存タスク**: タスク 8 で作成される Api::V1::BaseController（パス: `apps/rails/app/controllers/api/v1/base_controller.rb`、責務: 共通基底コントローラ（RecordNotFound の rescue_from を含む））
- **依存タスク**: タスク 10 で作成された SessionsController とルーティング設定（`config/routes.rb` の `:show` アクション）
- **依存タスク**: タスク 12 で作成される ClaudeCollector::SessionDetailResource（パス: `apps/rails/app/resources/claude_collector/session_detail_resource.rb`、責務: セッション詳細 JSON シリアライズ）

## 実装内容

- `SessionsController` に `show` アクションを追加する（`ClaudeCollector::Session.find_by!(session_id: params[:session_id])`）
- `SessionDetailResource` でシリアライズし `{ data: ... }` 形式でレスポンスする
- `spec/requests/api/v1/claude_collector/sessions_spec.rb` に rswag 形式で GET /api/v1/claude_collector/sessions/:session_id の request spec を追加する（正常系・404 エラー系）

## 依存タスク

タスク 2（RspecSetup）、タスク 4（RswagSetup）、タスク 8（BaseController）、タスク 10（SessionsController index）、タスク 12（SessionDetailResource）

## 完了条件

- `spec/requests/api/v1/claude_collector/sessions_spec.rb` の show テストがパスすること
- GET /api/v1/claude_collector/sessions/:session_id が `{ data: { ..., model_usages: [...] } }` 形式で応答すること
- 存在しない session_id を指定した場合に 404 `{ error: { code: "not_found", message: "..." } }` が返ること
