# サービス層ルール

## 責務

- ビジネスロジックを集約する
- Model にのみ依存する（Controller, Presenter, Resource には依存しない）
- 複数モデルにまたがるロジックや、コントローラに直接記述するには複雑すぎるロジックを担当する

## 現状

現時点ではサービス層は未使用。以下の導入基準に該当する場合に導入する。

## 導入基準

以下のいずれかに該当する場合、サービスクラスの導入を検討する:

- **複数モデルの協調**: 2つ以上のモデルにまたがるトランザクション処理
- **複雑なビジネスロジック**: コントローラのアクションメソッドが単純なCRUDを超えるロジックを持つ場合
- **再利用性**: 複数のコントローラアクションから共有されるロジック
- **外部サービス連携**: 外部APIとの通信を伴う処理

導入不要なケース:

- 単純なCRUD操作（モデルの `find`, `create`, `update`, `destroy` のみ）
- 単一モデルに対するクエリとレスポンス構築

## クラス名規約

| パターン | 命名例 | 用途 |
|---|---|---|
| 動詞 + 名詞 + Service | `CreateSessionService` | 作成処理 |
| 名詞 + 動詞 + Service | `SessionSyncService` | 同期処理 |
| 名前空間付き | `ClaudeCollector::ImportService` | ドメイン固有のサービス |

## call メソッド原則

サービスクラスのエントリーポイントは `call` メソッドとする。

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

module ClaudeCollector
  class ImportService
    # @rbs sessions_data: Array[Hash[Symbol, untyped]]
    # @rbs return: void
    def initialize(sessions_data)
      @sessions_data = sessions_data
    end

    # @rbs return: void
    def call
      # ビジネスロジック
    end
  end
end
```

呼び出し側:

```ruby
ClaudeCollector::ImportService.new(sessions_data).call
```

## 外部通信規約

外部 API との通信を行うサービスクラスには、以下のルールを適用する。

### タイムアウト

外部通信には必ずタイムアウトを設定する。

| 種別 | 推奨値 |
|---|---|
| 接続タイムアウト（`open_timeout`） | 5 秒 |
| 読取タイムアウト（`read_timeout`） | 30 秒 |

### リトライ

指数バックオフ付きリトライを適用する。

| 設定 | 値 |
|---|---|
| 最大リトライ回数 | 3 回 |
| バックオフ戦略 | 指数バックオフ（1秒, 2秒, 4秒） |

**リトライ対象**:
- ネットワークタイムアウト（`Net::OpenTimeout`, `Net::ReadTimeout`）
- サーバーエラー（HTTP 500, 502, 503, 504）

**リトライ非対象**:
- クライアントエラー（HTTP 4xx）
- 認証エラー（HTTP 401, 403）

### 例外処理

- 広範な `rescue StandardError` は禁止する
- 外部通信の例外は、ドメイン固有の例外クラスで再スローする

```ruby
module ClaudeCollector
  class ApiError < StandardError; end
  class ApiTimeoutError < ApiError; end
  class ApiResponseError < ApiError; end

  class ImportService
    def call
      response = fetch_data
      process(response)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise ApiTimeoutError, "External API timeout: #{e.message}"
    rescue Faraday::ClientError => e
      raise ApiResponseError, "External API error: #{e.message}"
    end
  end
end
```

## トランザクション整合性

データベーストランザクションを使用するサービスクラスには、以下のルールを適用する。

### トランザクション境界の明示

- トランザクション境界はサービスクラスの `call` メソッド内で明示的に宣言する
- コントローラやモデルではトランザクションを開始しない

```ruby
def call
  ActiveRecord::Base.transaction do
    # トランザクション内の処理
  end
end
```

### トランザクション内での外部通信禁止

トランザクション内で外部 API 通信を行わない。外部通信が必要な場合は、トランザクションの前後に分離する。

```ruby
# 良い例
def call
  external_data = fetch_from_api  # トランザクション外

  ActiveRecord::Base.transaction do
    save_to_database(external_data)  # トランザクション内
  end

  notify_external_service  # トランザクション外
end
```

### 重複防止

冪等キーまたはユニーク制約を利用し、重複実行を防止する。

- データベースレベルのユニーク制約（`add_index ... unique: true`）を第一選択とする
- アプリケーションレベルでの冪等キーチェックは補助的に使用する

## ファイル配置

```text
app/services/
  claude_collector/
    import_service.rb      # ClaudeCollector::ImportService
  application_service.rb   # 共通基底クラス（必要に応じて）
```

モデルと同様に、名前空間に対応するディレクトリ内にファイルを配置する。
