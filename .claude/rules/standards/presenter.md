# プレゼンタ層ルール

## 責務

- レスポンスのメタ情報を構造化する
- モデルのJSONシリアライズは担当しない（それは Resource の役割）

## alba Resource との住み分け

| 役割 | 担当 | 例 |
|---|---|---|
| モデル属性のJSONシリアライズ | Resource（alba） | `ClaudeCollector::SessionResource` |
| レスポンスメタ情報の構築 | Presenter | `PaginationMeta` |
| ネストされたリソースの組み立て | Resource（alba） | `ClaudeCollector::SessionDetailResource` |

Presenter はモデルそのものではなく、レスポンスに付随する補助情報（ページネーション、集計結果など）を構造化する。

## 実装パターン

### コンストラクタでオブジェクトを受け取る

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

class PaginationMeta
  # @rbs @collection: ActiveRecord::Relation[untyped]

  # @rbs collection: ActiveRecord::Relation[untyped]
  # @rbs return: void
  def initialize(collection)
    @collection = collection
  end

  # @rbs return: Hash[Symbol, Integer]
  def to_h
    {
      total_count: @collection.total_count,
      total_pages: @collection.total_pages,
      current_page: @collection.current_page
    }
  end
end
```

### to_h メソッド

Presenter は `to_h` メソッドでハッシュを返す。コントローラ側でレスポンスに組み込む。

```ruby
# コントローラでの使用例
render(json: {
  data: sessions.map { |s| ClaudeCollector::SessionResource.new(s).serialize },
  meta: PaginationMeta.new(sessions).to_h
})
```

## ファイル配置

```text
app/presenters/
  pagination_meta.rb     # PaginationMeta
```

Presenter はドメイン固有でない場合、`app/presenters/` 直下に配置する。ドメイン固有の場合は名前空間に対応するディレクトリを作成する。
