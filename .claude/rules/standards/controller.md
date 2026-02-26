# コントローラ層ルール

## 責務

- HTTPリクエストの受け取りとレスポンスの返却
- パラメータの取得と受け渡し
- Service / Model の呼び出し
- Presenter / Resource によるレスポンス構築

## 基底コントローラ

> **注記**: 以下は後続タスク（FUNC-007: セッション一覧 API）で実装予定のリファレンス実装である。現時点では未実装。

全 API コントローラは `Api::V1::BaseController` を継承する。

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      private

      # @rbs return: Hash[Symbol, Integer]
      def pagination_params
        {
          page: params[:page].to_i.clamp(1..),
          per: params[:per].to_i.clamp(1, 100)
        }
      end

      # @rbs error: ActiveRecord::RecordNotFound
      # @rbs return: void
      def render_not_found(error)
        render(json: { error: { code: 'not_found', message: error.message } }, status: :not_found)
      end

      # @rbs return: void
      def render_bad_request(message = 'Bad request')
        render(json: { error: { code: 'bad_request', message: message } }, status: :bad_request)
      end

      # @rbs return: void
      def render_unprocessable_entity(message = 'Unprocessable entity')
        render(json: { error: { code: 'unprocessable_entity', message: message } }, status: :unprocessable_entity)
      end
    end
  end
end
```

### pagination_params バリデーションルール

| パラメータ | 型変換 | 範囲制限 | デフォルト挙動 |
|---|---|---|---|
| `page` | `to_i` | 最小値 1（`clamp(1..)`） | 0 以下は 1 に補正 |
| `per` | `to_i` | 1 以上 100 以下（`clamp(1, 100)`） | 範囲外は境界値に補正 |

## 認証・認可

> **注記**: 現時点では認証・認可は未導入である（要件定義書にて「本スコープ対象外」と明記）。将来的な導入を想定し、以下の方針を定める。

### 導入方針

- `before_action` で全アクションに認証を必須とする
- 認証不要なアクションは `skip_before_action` で個別に除外する
- 認証失敗時は `401 Unauthorized`、認可失敗時は `403 Forbidden` を返す

### 導入時の実装イメージ

```ruby
class Api::V1::BaseController < ApplicationController
  before_action :authenticate!

  private

  def authenticate!
    # 認証ロジック（トークン検証等）
    render(json: { error: { code: 'unauthorized', message: 'Authentication required' } }, status: :unauthorized) unless current_user
  end

  def authorize!(resource)
    # 認可ロジック
    render(json: { error: { code: 'forbidden', message: 'Access denied' } }, status: :forbidden) unless authorized?(resource)
  end
end
```

## 名前空間

```text
Api::V1::<Domain>::<Resource>Controller
```

例:
- `Api::V1::ClaudeCollector::SessionsController`
- `Api::V1::ClaudeCollector::ModelUsagesController`

## レスポンス形式

### 一覧（ページネーション付き）

```json
{
  "data": [...],
  "meta": {
    "total_count": 100,
    "total_pages": 10,
    "current_page": 1
  }
}
```

### 詳細

```json
{
  "data": { ... }
}
```

### エラー

```json
{
  "error": {
    "code": "not_found",
    "message": "Record not found"
  }
}
```

## エラーハンドリング

### 共通エラーレスポンス形式

全てのエラーレスポンスは以下の JSON 構造に統一する。

```json
{
  "error": {
    "code": "エラーコード（snake_case）",
    "message": "人間が読めるエラーメッセージ"
  }
}
```

### ステータスコード対応表

| ステータスコード | エラーコード | 用途 |
|---|---|---|
| 400 Bad Request | `bad_request` | 不正なリクエストパラメータ |
| 401 Unauthorized | `unauthorized` | 認証失敗（将来導入） |
| 403 Forbidden | `forbidden` | 認可失敗（将来導入） |
| 404 Not Found | `not_found` | リソースが存在しない |
| 422 Unprocessable Entity | `unprocessable_entity` | バリデーションエラー |
| 500 Internal Server Error | `internal_server_error` | サーバー内部エラー |

### 実装ルール

- `ActiveRecord::RecordNotFound` は `Api::V1::BaseController` の `rescue_from` で捕捉し、404 JSON レスポンスを返す
- 個別のコントローラでは `rescue_from` を追加しない（基底コントローラに集約）
- 500 エラーはフレームワークのデフォルトハンドラに委ね、詳細なエラー情報はクライアントに返さない

## 禁止事項

- **ビジネスロジックをコントローラに書かない**: 複雑なロジックは Service に委譲する
- **モデルの直接的な操作ロジック**: 複数モデルにまたがる処理は Service に委譲する
- **レスポンス構造の構築ロジック**: Presenter / Resource に委譲する

## 参照専用コントローラ

参照専用 API では `index` / `show` アクションのみを定義する。ルーティングでも `only: [:index, :show]` で制限する。

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :claude_collector do
      resources :sessions, only: [:index, :show], param: :session_id
      resources :model_usages, only: [:index]
    end
  end
end
```

## ファイル配置

```text
app/controllers/
  application_controller.rb
  api/
    v1/
      base_controller.rb                          # Api::V1::BaseController
      claude_collector/
        sessions_controller.rb                    # Api::V1::ClaudeCollector::SessionsController
        model_usages_controller.rb                # Api::V1::ClaudeCollector::ModelUsagesController
```

ディレクトリ構造は名前空間に対応させる。
