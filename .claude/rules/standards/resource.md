# リソース層ルール

## 責務

- モデルの JSON シリアライズを担当する
- alba の Resource パターンに従う
- Model にのみ依存する（Controller, Service, Presenter には依存しない）

### Presenter との住み分け

| 層 | 責務 | 例 |
|---|---|---|
| Resource | モデル属性の JSON シリアライズ | セッションの `session_id`, `total_cost` 等の属性変換 |
| Presenter | メタ情報・集約情報の構築 | ページネーションメタ（`total_count`, `total_pages`） |

## 実装パターン

### 基本形

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

module ClaudeCollector
  class SessionResource
    include Alba::Resource

    root_key :session, :sessions

    attributes :session_id, :total_cost, :total_input_tokens, :total_output_tokens
  end
end
```

### ネストリソース

関連モデルを含む場合は `has_many` / `has_one` を使用する。

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

module ClaudeCollector
  class SessionDetailResource
    include Alba::Resource

    root_key :session

    attributes :session_id, :total_cost, :total_input_tokens, :total_output_tokens

    has_many :model_usages, resource: ClaudeCollector::ModelUsageResource
  end
end
```

### コントローラでの使用例

```ruby
def index
  sessions = ClaudeCollector::Session.page(page).per(per)
  render json: {
    data: ClaudeCollector::SessionResource.new(sessions).serialize,
    meta: PaginationMeta.new(sessions).to_h
  }
end

def show
  session = ClaudeCollector::Session.find_by!(session_id: params[:session_id])
  render json: { data: ClaudeCollector::SessionDetailResource.new(session).serialize }
end
```

## 命名規則

| 用途 | 命名パターン | 例 |
|---|---|---|
| 一覧用 | `<Model>Resource` | `SessionResource` |
| 詳細用（関連含む） | `<Model>DetailResource` | `SessionDetailResource` |

## ファイル配置

```text
app/resources/
  claude_collector/
    session_resource.rb              # ClaudeCollector::SessionResource
    session_detail_resource.rb       # ClaudeCollector::SessionDetailResource
    model_usage_resource.rb          # ClaudeCollector::ModelUsageResource
```

名前空間に対応するディレクトリ内にファイルを配置する。ファイル名はクラス名の snake_case 変換に従う。

## 禁止事項

- **ビジネスロジックの記述禁止**: 条件分岐や計算ロジックは Model または Service に委譲する
- **Presenter 責務の混入禁止**: ページネーション情報等のメタデータは Presenter で扱う
- **Controller 依存の禁止**: リクエストコンテキスト（`params`, `current_user` 等）に依存しない
