# タスク 7: PaginationMeta

## 対象機能

- FUNC-006: kaminari 導入
- FUNC-007: セッション一覧 API
- FUNC-009: モデル別利用量一覧 API

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-009: ページネーション機能の導入

## 種別

Shared Component Task

## 概要

ページネーションメタ情報を構造化する共通プレゼンタを作成する。FUNC-007（セッション一覧）とFUNC-009（モデル別利用量一覧）の両方で利用される

## 対象コンポーネント

- PaginationMeta（パス: `apps/rails/app/presenters/pagination_meta.rb`、責務: ページネーションメタ情報（total_count, total_pages, current_page）のレスポンス構造定義、種別: 新規）

## 利用するコンポーネント

- **依存タスク**: タスク 2 で作成される rspec 環境（パス: `apps/rails/spec/`、責務: テスト実行環境）
- **依存タスク**: タスク 6 で追加される kaminari（責務: page / per スコープ、total_count / total_pages / current_page メソッドの提供）

## 実装内容

- `app/presenters/pagination_meta.rb` に `PaginationMeta` クラスを作成する
  - `initialize(collection)` で kaminari ページネーション済みコレクションを受け取る
  - `to_h` で `{ total_count:, total_pages:, current_page: }` を返す
- `spec/presenters/pagination_meta_spec.rb` を作成しテストする

## 依存タスク

タスク 2（RspecSetup）、タスク 6（KaminariSetup）

## 完了条件

- `spec/presenters/pagination_meta_spec.rb` のテストがパスすること
