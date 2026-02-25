# タスク01: CodingRulesFiles

## 対象機能

FUNC-001: コーディングルールファイル作成

## 関連ドキュメント

- **要件定義**: docs/development-flow/requirement.md
- **基本設計**: docs/development-flow/design.md

## 関連要件

REQ-008: コーディングルールファイルの導入

## 種別

Config Task

## 概要

aitally プロジェクト向けのコーディングスタンダード・設計ルールを 7 種のドキュメントとして `docs/coding-rules/` に作成・配置する。このタスクは、プロジェクト全体のコーディング規約（命名規則、ファイル構成、レイヤー構造）と、各レイヤー（Controller、Service、Model、Presenter）の責務分離ルールを定義し、テスト規約と RBS 型定義規約の基盤を確立する。

## 対象コンポーネント

- coding-standards.md（パス: `docs/coding-rules/coding-standards.md`、責務: プロジェクト全体のコーディング規約（命名規則、ファイル構成、レイヤー構造の概要と依存方向のルール）、種別: 新規）
- controller.md（パス: `docs/coding-rules/controller.md`、責務: コントローラ層の責務と実装ルール、種別: 新規）
- model-rules.md（パス: `docs/coding-rules/model-rules.md`、責務: モデル層の責務と実装ルール、種別: 新規）
- presenter.md（パス: `docs/coding-rules/presenter.md`、責務: プレゼンタ層の責務と実装ルール、種別: 新規）
- rbs.md（パス: `docs/coding-rules/rbs.md`、責務: rbs-inline の記述規約（プロジェクト内の既存ルールとの整合）、種別: 新規）
- services.md（パス: `docs/coding-rules/services.md`、責務: サービス層の責務と実装ルール、種別: 新規）
- testing-rules.md（パス: `docs/coding-rules/testing-rules.md`、責務: テストの記述規約（rspec のスタイル、カバレッジ方針）、種別: 新規）

## 利用するコンポーネント

- **既存**: `.claude/rules/standards/rbs.md`（責務: プロジェクト内の既存 RBS ルール、rbs.md 作成時の整合対象）

## 実装内容

- `docs/coding-rules/` ディレクトリを作成する
- `coding-standards.md` を作成する（命名規則、ファイル構成、レイヤー構造の概要、Controller → Service → Model の依存方向のルール）
- `controller.md` を作成する（コントローラ層の責務範囲、実装ルール）
- `model-rules.md` を作成する（モデル層の責務範囲、実装ルール）
- `presenter.md` を作成する（プレゼンタ層の責務範囲、実装ルール）
- `rbs.md` を作成する（rbs-inline の記述規約、`.claude/rules/standards/rbs.md` との整合を取る）
- `services.md` を作成する（サービス層の責務範囲、実装ルール）
- `testing-rules.md` を作成する（rspec のスタイル、カバレッジ 100% 方針）

## 依存タスク

なし

## 完了条件

- `docs/coding-rules/` 配下に 7 ファイルが存在すること
- 各ファイルが aitally プロジェクトの開発方針に沿ったルールを定義していること
- `coding-standards.md` にレイヤー構造に基づく責務分離ルール（各レイヤーの責務範囲と依存方向）が記載されていること
