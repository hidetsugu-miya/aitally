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

## 実行履歴

### 実行1

#### implementer
- ステータス: 完了
- 概要: docs/coding-rules/ 配下に7つのコーディングルールファイルを作成（coding-standards.md, controller.md, model-rules.md, presenter.md, rbs.md, services.md, testing-rules.md）

#### CI
- 結果: PASS
- 実行方法: make ci

#### コードレビュー

**サマリー**:
- 安全性: 6件（Critical: 0, Major: 6, Minor: 5）
- 品質: 4件（Critical: 0, Major: 4, Minor: 5）
- 根拠確認: 10/12件

**Critical / Major 指摘**:

**[Major_1] 認証・認可規約の欠如**
- 担当: @SafetyReviewer
- 指摘元: [Both]
- 観点: セキュリティ
- 箇所: `docs/coding-rules/controller.md` (責務定義・エラーハンドリングセクション全体)
- 現状: controller.md に認証・認可に関する記載が一切ない。BaseController に認証フィルタ（before_action等）の規約がなく、APIエンドポイントが無防備になるリスクがある
- 提案: 認証方式（トークン認証、OAuth等）と認可ポリシーの規約を追加すべき

**[Major_2] pagination_params の入力バリデーション欠如**
- 担当: @SafetyReviewer
- 指摘元: [Both]
- 観点: セキュリティ / データ整合性
- 箇所: `docs/coding-rules/controller.md:27-31` (pagination_params)
- 現状: `pagination_params` は `params[:page]` と `params[:per]` をそのまま渡しており、整数変換・範囲制限がない。巨大な per 値によるDoS的なクエリ発行や、負数・非数値入力による予期しない挙動のリスクがある
- 提案: Integer 変換、最小値1、最大値上限（例: per は最大100）、不正値時のデフォルト値またはエラーレスポンスのルールを追加

**[Major_3] 参照専用モデルの書き込み防止が未強制**
- 担当: @SafetyReviewer
- 指摘元: [Both]
- 観点: データ整合性
- 箇所: `docs/coding-rules/model-rules.md:20` (connects_to)
- 現状: `connects_to database: { writing: :claude_collector, reading: :claude_collector }` で writing ロールが指定されており、参照専用モデルにもかかわらず書き込みが可能な状態
- 提案: 参照専用モデルには `writing` ロールの除外、または `readonly!` メソッドの強制など、書き込み防止策の規約が必要

**[Major_4] 外部通信時のエラーハンドリング・リトライ戦略の欠如**
- 担当: @SafetyReviewer
- 指摘元: [Both]
- 観点: エラーハンドリング
- 箇所: `docs/coding-rules/services.md:17-20` (導入基準)
- 現状: 「外部APIとの通信を伴う処理」が導入基準として記載されているが、タイムアウト設定、リトライ戦略、サーキットブレーカーなどの具体的なエラーハンドリング規約がない
- 提案: 外部通信の「タイムアウト必須」「指数バックオフ付き限定リトライ」「非リトライ例外の明示」を標準化

**[Major_5] 冪等性・トランザクション整合性の規約欠如**
- 担当: @SafetyReviewer
- 指摘元: [Both]
- 観点: データ整合性
- 箇所: `docs/coding-rules/services.md:17` (トランザクション処理)
- 現状: 「2つ以上のモデルにまたがるトランザクション処理」の言及があるが、トランザクションの使用方法、冪等性の確保方法、部分失敗時のロールバック戦略が未定義
- 提案: トランザクション境界の明示ルール、冪等キーまたはユニーク制約による重複防止を追加

**[Major_6] セキュリティ回帰テストの不在**
- 担当: @SafetyReviewer
- 指摘元: [Both]
- 観点: セキュリティ
- 箇所: `docs/coding-rules/testing-rules.md` (APIテストセクション)
- 現状: testing-rules.md にセキュリティテスト（認証・認可テスト、権限境界テスト等）への言及がない
- 提案: APIテストで必須のセキュリティテストケース（認証不在時401、認可不足時403、入力異常系400）を明記

**[Major_7] BaseController が規約に定義済みだが未実装**
- 担当: @QualityReviewer
- 指摘元: [Both]
- 観点: コード品質
- 箇所: `docs/coding-rules/controller.md:14-40` (BaseController定義)
- 現状: `Api::V1::BaseController` のコードが規約として定義されているが、`app/controllers/api/v1/base_controller.rb` が存在しない
- 提案: 規約文書として問題ないが、後続タスクで実装予定であることを明記すると混乱を防げる

**[Major_8] APIエラーハンドリング規約が 404 のみで不足**
- 担当: @QualityReviewer
- 指摘元: [Both]
- 観点: API設計
- 箇所: `docs/coding-rules/controller.md:87-90` (エラーハンドリング)
- 現状: `RecordNotFound`（404）のみ。400、422、500等の標準HTTPエラーの扱いが未定義
- 提案: 共通エラーレスポンス形式にステータスコード対応表を追加

**[Major_9] テスト基盤が未導入の状態で規約のみ先行**
- 担当: @QualityReviewer
- 指摘元: [Codex]
- 観点: テスト
- 箇所: `docs/coding-rules/testing-rules.md` (全体)
- 現状: RSpec, SimpleCov, rswag が Gemfile に含まれておらず、spec ディレクトリも存在しない。規約が実行不能な状態
- 提案: testing-rules.md 冒頭にスコープ注記を追加

**[Major_10] Resource層のルールドキュメントが欠落**
- 担当: @QualityReviewer
- 指摘元: [Claude]
- 観点: コード品質
- 箇所: `docs/coding-rules/` (ディレクトリ全体)
- 現状: coding-standards.md に Resource（alba）が記載され、presenter.md にも住み分けが説明されているが、Resource層の専用規約ドキュメントが存在しない
- 提案: `docs/coding-rules/resource.md` を追加し、alba Resource の実装パターンを定義

**Minor 指摘**:

- 例外捕捉の粒度ルール未定義 @SafetyReviewer (エラーハンドリング) [Both]
- 例外再スロー時の cause 保持ルール未定義 @SafetyReviewer (エラーハンドリング) [Both]
- SQL/コマンドインジェクション/パストラバーサル防止の実装指針未記載 @SafetyReviewer (セキュリティ) [Both]
- 楽観ロック（lock_version）適用基準の未定義 @SafetyReviewer (データ整合性) [Both]
- 機密情報のログ出力禁止ルール未記載 @SafetyReviewer (セキュリティ) [Claude]
- 「全ファイルに frozen_string_literal」の記述粒度が不正確 @QualityReviewer (コード品質) [Both]
- rbs.md の参照パスの基準が曖昧 @QualityReviewer (コード品質) [Both]
- パス基準が apps/rails 基準かリポジトリルート基準か曖昧 @QualityReviewer (コード品質) [Both]
- services.md: @sessions_data の rbs アノテーション欠落 @QualityReviewer (コード品質) [Claude]
- パフォーマンステストへの言及なし @QualityReviewer (テスト) [Claude]

### 実行2

#### implementer
- ステータス: 完了
- 概要: iteration 1 のレビュー指摘 Major 9件を修正（Major_9はユーザー判断でスキップ）。controller.md に認証・認可セクション追加、pagination_params バリデーション追加、BaseController注記追加、エラーハンドリング拡充。model-rules.md に参照専用モデル書き込み防止規約追加。services.md に外部通信規約・トランザクション整合性セクション追加。testing-rules.md にセキュリティテストケース追加。resource.md を新規作成。

#### CI
- 結果: PASS
- 実行方法: make ci

#### コードレビュー

**サマリー**:
- 安全性: 4件（Critical: 0, Major: 4, Minor: 1）
- 品質: 8件（Critical: 0, Major: 6, Minor: 2（Majorから引き下げ2件含む））
- 根拠確認: 12/12件

**Critical / Major 指摘**:

**[Major_1] `readonly!` 方針が `create` を防げない記述の不正確さ**
- 担当: @SafetyReviewer（@QualityReviewer Critical_2 と統合）
- 指摘元: [Both]
- 観点: データ整合性 / バリデーション・条件式の論理的正しさ
- 箇所: `docs/coding-rules/model-rules.md:49` (after_initialize :readonly!)
- 現状: `after_initialize :readonly!, if: :persisted?` は新規レコードに対して readonly! を呼ばない。L53 の create 時に例外発生する旨の記述が実動作と不一致
- 提案: create は persisted? 条件により防げないことを明記。完全な書き込み防止にはDB権限レベルか `def readonly? = true` オーバーライドを記載

**[Major_2] `render_not_found` の `error.message` による内部情報露出**
- 担当: @SafetyReviewer
- 指摘元: [Both]
- 観点: セキュリティ（機密情報露出）
- 箇所: `docs/coding-rules/controller.md:39` (render_not_found)
- 現状: error.message にモデル名・ID値が含まれ、JSONレスポンスでクライアントに内部実装情報が露出する
- 提案: 固定文言（"Resource not found"）に統一し、詳細はサーバーログのみ

**[Major_3] `pagination_params` の暗黙補正による不正入力検知の阻害**
- 担当: @SafetyReviewer（@QualityReviewer Critical_1 と統合）
- 指摘元: [Both]
- 観点: バリデーション・条件式の論理的正しさ
- 箇所: `docs/coding-rules/controller.md:31` (pagination_params) + `testing-rules.md:175`
- 現状: to_i.clamp で不正値が自動補正され、testing-rules.md の400必須テストケースと矛盾
- 提案: 設計方針を統一する（明示的バリデーションで400を返すか、暗黙補正を許容するか）

**[Major_4] リトライ規約に冪等性条件が未定義**
- 担当: @SafetyReviewer
- 指摘元: [Both]
- 観点: データ整合性
- 箇所: `docs/coding-rules/services.md:86-94` (リトライ対象)
- 現状: タイムアウト・5xxで一律リトライだが、非冪等操作でのリトライリスクに言及なし
- 提案: リトライは冪等操作に限定するか、非冪等操作では冪等キー必須を明記

**[Major_5] per パラメータ未指定時のデフォルトが 1 になる**
- 担当: @QualityReviewer
- 指摘元: [Both]
- 観点: パフォーマンス、API設計
- 箇所: `docs/coding-rules/controller.md:33` (pagination_params)
- 現状: nil.to_i → 0 → clamp(1, 100) = 1。ページあたり1件は実用的でない
- 提案: 明示的なデフォルト値（DEFAULT_PER_PAGE = 20）を設定

**[Major_6] 500 エラーの JSON レスポンス方針が矛盾**
- 担当: @QualityReviewer
- 指摘元: [Both]
- 観点: API設計（一貫性）
- 箇所: `docs/coding-rules/controller.md:141-142, 167` (エラーハンドリング)
- 現状: 「全エラーをJSON統一」と「500はフレームワークデフォルト」が矛盾
- 提案: 「500は例外的にフレームワークデフォルトとする」旨を明記

**[Major_7] presenter.md と resource.md でコレクションシリアライズ方法が不整合**
- 担当: @QualityReviewer
- 指摘元: [Both]
- 観点: コード品質（一貫性）
- 箇所: `docs/coding-rules/presenter.md:54` vs `resource.md:64`
- 現状: presenter.md で個別シリアライズ、resource.md でコレクション一括シリアライズが混在
- 提案: Resource.new(sessions).serialize に統一

**[Major_8] マルチ DB 環境での ActiveRecord::Base.transaction 使用**
- 担当: @QualityReviewer
- 指摘元: [Codex]
- 観点: 設計・実装品質（依存関係の適切性）
- 箇所: `docs/coding-rules/services.md:131` (transaction)
- 現状: ActiveRecord::Base.transaction を標準としているがマルチDB構成で意図しないコネクション
- 提案: 対象モデルクラスでトランザクションを開始するルールに変更

**[Major_9] 外部通信例外例で Faraday を参照しているが Gemfile に未定義**
- 担当: @QualityReviewer
- 指摘元: [Codex]
- 観点: 設計・実装品質（既存コードとの一貫性）
- 箇所: `docs/coding-rules/services.md:113` (Faraday::ClientError)
- 現状: Faraday が Gemfile に未定義
- 提案: gem 非依存の例に修正

**[Major_10] rswag スキーマ例が粗く契約テストとして不十分**
- 担当: @QualityReviewer
- 指摘元: [Both]
- 観点: テスト（アサーションの品質）
- 箇所: `docs/coding-rules/testing-rules.md:141-148` (schema)
- 現状: スキーマが data: { type: :array }, meta: { type: :object } のみで契約テストとして機能しない
- 提案: 厳密なスキーマ例（items, required, properties）を記載

**Minor 指摘**:

- root_key と data ラッパーの二重構造リスク @QualityReviewer (API設計) [Codex]（Majorから引き下げ: 実装時にのみ顕在化）
- 可観測性（ログ・トレーサビリティ）の規約が欠落 @QualityReviewer (可観測性) [Both]（Majorから引き下げ: 段階的整備の方針）
- 例外再スロー時の外部エラー本文露出 @SafetyReviewer (セキュリティ) [Both]
- API エラーレスポンスに details フィールドの規約がない @QualityReviewer (API設計) [Codex]
- ページネーション meta に per / next_page / prev_page の契約がない @QualityReviewer (API設計) [Both]
- Typed 100% の測定対象・CI ゲート条件が未定義 @QualityReviewer (プロセス) [Codex]
- ドキュメント内の「未実装リファレンス」と「必須ルール」の境界が曖昧 @QualityReviewer (ドキュメント品質) [Claude]
