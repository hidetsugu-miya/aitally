# タスク5: AlbaSetup

## 対象機能

FUNC-005: alba 導入

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-004: JSONシリアライザの導入

## 種別

Config Task

## 概要

API レスポンスの JSON 構造を alba の Resource パターンで統一的に定義・管理する環境を構築する

## 対象コンポーネント

- Gemfile（パス: `apps/rails/Gemfile`、責務: alba gem の追加、種別: 修正）
- app/resources/（パス: `apps/rails/app/resources/`、責務: Resource クラスの格納ディレクトリ、種別: 新規）

## 利用するコンポーネント

なし

## 実装内容

- `Gemfile` に `alba` を追加する
- `app/resources/` ディレクトリを作成する
- 必要に応じて `config/initializers/alba.rb` を作成し、`transform_keys` の方針（`:snake`）等を設定する

## 依存タスク

なし

## 完了条件

- alba の Resource クラスが利用可能なこと（`include Alba::Resource` が動作すること）
- `app/resources/` ディレクトリが存在すること
