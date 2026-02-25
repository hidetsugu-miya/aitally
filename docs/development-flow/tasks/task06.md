# タスク6: KaminariSetup

## 対象機能

FUNC-006: kaminari 導入

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-009: ページネーション機能の導入

## 種別

Config Task

## 概要

一覧系 API でページネーション機能を提供する。kaminari を導入し、page / per スコープを ActiveRecord モデルで利用可能にする

## 対象コンポーネント

- Gemfile（パス: `apps/rails/Gemfile`、責務: kaminari gem の追加、種別: 修正）
- kaminari_config.rb（パス: `apps/rails/config/initializers/kaminari_config.rb`、責務: kaminari のデフォルト設定（default_per_page 等）、種別: 新規）

## 利用するコンポーネント

- なし

## 実装内容

- `Gemfile` に `kaminari` を追加する
- `config/initializers/kaminari_config.rb` を作成し、デフォルトの `per_page` を設定する（例: 25）

## 依存タスク

なし

## 完了条件

- kaminari の `page` / `per` スコープが ActiveRecord モデルで利用できること
