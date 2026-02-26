# コーディング規約

## 基本方針

- 全ファイルに `# frozen_string_literal: true` を記載する
- 全 Ruby ファイルに `# rbs_inline: enabled` を記載する
- Ruby 4.0 / Rails 8.1 を対象とする
- RuboCop 準拠（`.rubocop.yml` に従う）

## 命名規則

| 対象 | 規則 | 例 |
|---|---|---|
| クラス名 | UpperCamelCase | `SessionsController`, `PaginationMeta` |
| モジュール名 | UpperCamelCase | `ClaudeCollector`, `Api::V1` |
| メソッド名 | snake_case | `pagination_params`, `find_by_session_id` |
| 変数名 | snake_case | `total_count`, `current_page` |
| 定数 | SCREAMING_SNAKE_CASE | `DEFAULT_PER_PAGE`, `MAX_RETRY_COUNT` |
| ファイル名 | snake_case.rb | `session_resource.rb`, `pagination_meta.rb` |

## ファイル構成

```text
app/
  controllers/       # HTTPリクエスト処理
    api/v1/          # API v1 名前空間
  models/            # データアクセスとドメインロジック
  services/          # ビジネスロジック集約
  presenters/        # レスポンスメタ情報構築
  resources/         # JSONシリアライズ定義（alba）
spec/
  requests/          # APIリクエストテスト（rswag形式）
  models/            # モデルテスト
  services/          # サービステスト
  presenters/        # プレゼンタテスト
  resources/         # リソーステスト
```

## レイヤー構造と依存方向

### レイヤー構成

```text
Controller  -->  Service  -->  Model
    |                            ^
    +------- Presenter           |
    |                            |
    +------- Resource -----------+
```

### 各レイヤーの責務

| レイヤー | 責務 | 依存先 |
|---|---|---|
| Controller | HTTPリクエスト処理、レスポンス構築 | Service, Model, Presenter, Resource |
| Service | ビジネスロジック集約 | Model のみ |
| Model | データアクセスとドメインロジック | なし（他レイヤーに依存しない） |
| Presenter | レスポンスメタ情報の構造化 | なし（受け取ったオブジェクトの変換のみ） |
| Resource | モデルのJSONシリアライズ | Model のみ |

### 依存方向ルール

- **許可**: Controller -> Service -> Model（上位から下位への依存）
- **許可**: Controller -> Presenter, Controller -> Resource
- **禁止**: Model -> Service, Model -> Controller（逆方向依存）
- **禁止**: Service -> Controller（逆方向依存）
- **禁止**: Model -> Presenter, Model -> Resource

### Presenter と Resource の住み分け

| 役割 | 担当 | 例 |
|---|---|---|
| モデルのJSONシリアライズ | Resource（alba） | `ClaudeCollector::SessionResource` |
| レスポンスメタ情報の構築 | Presenter | `PaginationMeta` |

Presenter はページネーション情報などレスポンス構造の付加情報を構築する。Resource はモデルの属性をJSON形式に変換する。

## RuboCop 準拠ルール

プロジェクトの `.rubocop.yml` に準拠する。主要な設定:

- `Style/MethodCallWithArgsParentheses`: 引数付きメソッド呼び出しには括弧を使用する
- `Style/HashSyntax`: Ruby 1.9 スタイル、省略記法を常に使用する
- `Layout/LineLength`: 最大150文字
- `Layout/LeadingCommentSpace`: RBS インラインアノテーション（`#:`）を許可する
- `RSpec/MultipleExpectations`: 1テストにつき expect は1つ（`:aggregate_failures` 使用時を除く）
- `RSpec/VerifiedDoubles`: `instance_double` を使用する（`double` は使用しない）
- `RSpec/AnyInstance`: `allow_any_instance_of` は使用しない
