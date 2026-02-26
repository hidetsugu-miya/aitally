# モデル層ルール

## 責務

- データアクセスとドメインロジックを担当する
- 他のレイヤー（Controller, Service, Presenter, Resource）に依存しない

## 抽象クラス

外部データベースへの接続は抽象クラスで管理する。

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

class ClaudeCollectorRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :claude_collector, reading: :claude_collector }
end
```

`ApplicationRecord` はデフォルトデータベース、`ClaudeCollectorRecord` は claude_collector データベースに接続する。新しいデータベース接続が必要な場合は、同様のパターンで抽象クラスを追加する。

## 参照専用モデルの書き込み防止

外部データベースから読み取りのみを行うモデルには、アプリケーションレベルでの書き込み防止策を適用する。

### 方針

- `writing` ロールは Rails のマルチDB機構（`connects_to`）上必須のため、データベース設定としては残す
- アプリケーションレベルで `readonly!` を設定し、意図しない書き込みを防止する

### 推奨パターン

抽象クラスに `after_initialize` コールバックで `readonly!` を設定する。

```ruby
# frozen_string_literal: true

# rbs_inline: enabled

class ClaudeCollectorRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :claude_collector, reading: :claude_collector }

  after_initialize :readonly!, if: :persisted?
end
```

`if: :persisted?` を指定することで、既存レコードのみを読み取り専用とする。これにより、万が一 `create` / `update` / `destroy` が呼び出された場合は `ActiveRecord::ReadOnlyRecord` 例外が発生する。

## 名前空間

関連するモデルはモジュールでグループ化する。

```ruby
# app/models/claude_collector/session.rb
module ClaudeCollector
  class Session < ClaudeCollectorRecord
    # ...
  end
end
```

## table_name の明示

名前空間付きモデルでは `self.table_name` を明示的に設定する。Rails のデフォルトではモジュール名がプレフィックスとして付与されるため、実際のテーブル名と一致しない場合がある。

```ruby
module ClaudeCollector
  class Session < ClaudeCollectorRecord
    self.table_name = 'sessions'
  end
end
```

## アソシエーション

- `class_name` を明示する（名前空間付きモデルでは自動解決されない場合がある）
- `inverse_of` を明示する（双方向の関連を明確にする）
- 参照専用モデルでは `dependent: false` を使用する

```ruby
module ClaudeCollector
  class Session < ClaudeCollectorRecord
    self.table_name = 'sessions'

    has_many :model_usages,
             class_name: 'ClaudeCollector::ModelUsage',
             inverse_of: :session,
             dependent: false
  end
end

module ClaudeCollector
  class ModelUsage < ClaudeCollectorRecord
    self.table_name = 'model_usages'

    belongs_to :session,
               class_name: 'ClaudeCollector::Session',
               inverse_of: :model_usages
  end
end
```

## バリデーション

- 参照専用モデル（外部データベースから読み取りのみ）ではバリデーションを定義しない
- 書き込みが必要なモデルでは適切なバリデーションを定義する

## ファイル配置

```text
app/models/
  application_record.rb          # デフォルトDB抽象クラス
  claude_collector_record.rb     # claude_collector DB抽象クラス
  claude_collector/              # ClaudeCollector名前空間
    session.rb                   # ClaudeCollector::Session
    model_usage.rb               # ClaudeCollector::ModelUsage
  concerns/                      # 共有ロジック（モジュール）
```

モジュール名に対応するディレクトリ内にファイルを配置する。ファイル名はクラス名の snake_case 変換に従う。
