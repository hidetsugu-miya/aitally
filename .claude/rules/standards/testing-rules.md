# テスト規約

## テストフレームワーク

RSpec を使用する。

## カバレッジ

- SimpleCov でカバレッジを計測する
- **line + branch カバレッジ 100% を必須とする**
- `SimpleCov.minimum_coverage` で 100% を設定し、未達の場合はテスト失敗とする

## ディレクトリ構成

```text
spec/
  requests/        # APIリクエストテスト（rswag request spec形式）
  models/          # モデルテスト
  services/        # サービステスト
  presenters/      # プレゼンタテスト
  resources/       # リソーステスト（alba Resource）
  rails_helper.rb  # Rails統合テスト用ヘルパー
  spec_helper.rb   # RSpec基本設定
  swagger_helper.rb # rswag設定
```

テストファイルのパスは実装ファイルのパスに対応させる。

```text
app/models/claude_collector/session.rb
  -> spec/models/claude_collector/session_spec.rb

app/controllers/api/v1/claude_collector/sessions_controller.rb
  -> spec/requests/api/v1/claude_collector/sessions_spec.rb

app/resources/claude_collector/session_resource.rb
  -> spec/resources/claude_collector/session_resource_spec.rb

app/presenters/pagination_meta.rb
  -> spec/presenters/pagination_meta_spec.rb
```

## RSpec スタイル

### described_class

テスト対象クラスは `described_class` で参照する。

```ruby
RSpec.describe ClaudeCollector::Session do
  describe '.find_by' do
    it 'returns the session' do
      expect(described_class.find_by(session_id: 'abc')).to be_a(described_class)
    end
  end
end
```

### subject / let

- `subject` でテスト対象の操作を定義する
- `let` で必要なデータを遅延評価で定義する

```ruby
RSpec.describe PaginationMeta do
  subject(:meta) { described_class.new(collection) }

  let(:collection) { ClaudeCollector::Session.page(1).per(10) }

  describe '#to_h' do
    it 'returns pagination metadata' do
      expect(meta.to_h).to include(:total_count, :total_pages, :current_page)
    end
  end
end
```

### context

条件分岐ごとに `context` でグループ化する。

```ruby
describe '#show' do
  context 'セッションが存在する場合' do
    it 'セッション詳細を返す' do
      # ...
    end
  end

  context 'セッションが存在しない場合' do
    it '404を返す' do
      # ...
    end
  end
end
```

RuboCop の `RSpec/ContextWording` は無効化されているため、`context` の文言に `when` / `with` / `without` の制約はない。

### :aggregate_failures

1つの example 内で複数の expect を使用する場合は `:aggregate_failures` タグを使用する。

```ruby
it 'returns session attributes', :aggregate_failures do
  expect(response).to have_http_status(:ok)
  expect(json['data']).to include('session_id' => 'abc-123')
end
```

`RSpec/MultipleExpectations` が `Max: 1` に設定されているため、複数 expect は `:aggregate_failures` を付けて使用する。

### instance_double

テストダブルは `instance_double` を使用する（`double` は使用しない）。`RSpec/VerifiedDoubles` が有効なため、存在しないメソッドのスタブはエラーになる。

```ruby
let(:session) { instance_double(ClaudeCollector::Session, session_id: 'abc-123') }
```

`allow_any_instance_of` は使用しない（`RSpec/AnyInstance` が有効）。

## API テスト

### rswag request spec 形式

API テストは rswag の request spec 形式で記述する。テスト実行と同時に OpenAPI ドキュメントを生成する。

```ruby
require 'swagger_helper'

RSpec.describe 'Api::V1::ClaudeCollector::Sessions' do
  path '/api/v1/claude_collector/sessions' do
    get 'セッション一覧を取得する' do
      tags 'Sessions'
      produces 'application/json'
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per, in: :query, type: :integer, required: false

      response '200', 'セッション一覧' do
        schema type: :object, properties: {
          data: { type: :array },
          meta: { type: :object }
        }

        run_test!
      end
    end
  end
end
```

### テスト実行

```bash
cd apps/rails
docker compose exec app bundle exec rspec
```

特定ファイルのみ実行する場合はコンテナ内パスを指定する。

```bash
docker compose exec app bundle exec rspec /app/spec/requests/api/v1/claude_collector/sessions_spec.rb
```

### 必須テストケース（異常系）

API テストでは、正常系に加えて以下の異常系テストケースを必ず含める。

#### 現時点の必須テスト

| ステータスコード | テスト内容 | 例 |
|---|---|---|
| 404 Not Found | 存在しないリソースへのアクセス | 存在しない `session_id` での `GET /sessions/:session_id` |
| 400 Bad Request | 不正なリクエストパラメータ | 不正な型・範囲外の値でのリクエスト |

#### 認証導入後に追加するテスト

| ステータスコード | テスト内容 |
|---|---|
| 401 Unauthorized | 認証トークンなし・無効なトークンでのアクセス |
| 403 Forbidden | 認証済みだが権限のないリソースへのアクセス |
