---
paths: sig/**/*.rbs, Steepfile, rbs_collection.yaml, lib/**/*.rb
---

# RBS型定義規約

- AIが新規作成・修正したファイルは **Typed 100%** を目指す

## rbs-inline 記法

**rbs-inline 形式を必ず使用する。** shim（`sig/shim/`）は外部ライブラリの型定義補完にのみ使用し、自作コードには一切使用しない。

### メソッド（引数・戻り値）

Boolean型は `bool`、戻り値なしは `void` を使用する。

```ruby
# rbs_inline: enabled

class UsersService
  # @rbs id: Integer
  # @rbs return: User | nil
  def find(id)
    User.find_by(id:)
  end

  # @rbs user: User
  # @rbs return: void
  def notify(user)
    UserMailer.welcome(user).deliver_later
  end
end
```

### インスタンス変数

型定義は **クラスレベル**（メソッドの外）に記載する。メソッドのドキュメントコメント内に記載しても RBS 型定義として出力されない。

```ruby
# rbs_inline: enabled

class UsersService
  # @rbs @user: User
  # @rbs @name: String?

  # @rbs user: User
  # @rbs return: void
  def initialize(user)
    @user = user
    @name = user.name
  end
end
```

### クラスメソッド（@rbs!）

`enum`、delegate など、フレームワークが自動生成するクラスメソッドは `@rbs!` ブロックで定義する。ブロック内は RBS 構文をそのまま記述する。

```ruby
# rbs_inline: enabled

class User < ApplicationRecord
  # @rbs!
  #   def self.active: () -> ActiveRecord_Relation
  #   def self.inactive: () -> ActiveRecord_Relation

  enum :status, { active: 'active', inactive: 'inactive' }
end
```

### 定数（#:）

shim ではなくインライン形式（`#:`）を使用。複数行定数の `#:` は式の最終行に記述する。

```ruby
MAX_COUNT = 10 #: Integer
VALID_TYPES = %w[foo bar].freeze #: Array[String]

# Good: 最終行に #:
COLUMN_MAPPING = {
  name: :string,
  age: :integer
}.freeze #: Hash[Symbol, Symbol]

# Bad: 代入行に #:（複数行式では認識されない）
COLUMN_MAPPING = { #: Hash[Symbol, Symbol]
  name: :string
}.freeze
```

## shim

外部ライブラリの型定義が不足している場合にのみ `sig/shim/` を使用する。

```rbs
# sig/shim/rollbar.rbs
module Rollbar
  def self.error: (untyped exception, ?untyped? extra) -> void
end
```

## 型エラーの解決

### 解決手段の優先順位

1. **`attr_reader` + `#:` アサーション** — nullable型のナローイングに最優先
2. **`# @type var`** — gem RBS定義がランタイム動作と不一致の場合
3. **コードレベル修正** — nil guard + ローカル変数代入でフロー制御型を活用
4. **`# steep:ignore`** — 上記いずれも適用不可な場合の最終手段

### ナローイング（#: アサーション）

nullable型（`T?`）を non-null型（`T`）にナローイングする手法。一時変数を導入せず解決する。

**パターン1（推奨）: `attr_reader` + ハッシュ省略記法**

`attr_reader` が存在する場合、ハッシュ省略記法と `#:` を組み合わせて一時変数を排除する。`attr_reader` の型注釈がRBSにも反映されるため最優先。

```ruby
attr_reader :user #: User?

def update
  Users::UpdateService.new(
    user:, #: User
    params:
  ).call
end
```

**パターン2: 明示的な値指定**

`attr_reader` が存在しない場合でも、明示的な値指定で `#:` を使用できる。

```ruby
# @rbs @user: User?

def update
  Users::UpdateService.new(
    user: @user, #: User
    params:
  ).call
end
```

**避けるべきパターン**: 型ナローイングのためだけに一時変数を導入する。

```ruby
# Bad
def update
  user = @user #: User
  Users::UpdateService.new(user:, params:).call
end
```

### gem型定義の不一致（# @type var）

shim ファイルでは `DuplicatedMethodDefinitionError` が発生するため上書きできない。`# @type var` で正しい型を指定する。

```ruby
# 典型例: ActiveModel::Errors#each
# gem RBSでは [untyped, untyped] タプルだが、Rails 6.1+ は ActiveModel::Error を yield する
model.errors.each do |error|
  # @type var error: ActiveModel::Error
  @errors.push(field: error.attribute, code: error.type, message: error.full_message)
end
```

### steep:ignore

型情報が分かっている場合は `# @type var` を優先すること。

- **`# @type var`**: 型安全性を維持（以降のメソッド呼び出しも型チェックされる）
- **`# steep:ignore`**: その行の型チェックを完全にスキップ

## 既知の制限

### Struct.new + ブロック構文

Steep は Struct.new のブロック内メソッド定義を認識できない。該当行に `# steep:ignore` を追加（理由をコメントで明記）。

```ruby
# NOTE: Struct.new + ブロック構文はSteepの型推論が困難なため steep:ignore を使用
ProcessingResult = Struct.new(:inserted, :updated, keyword_init: true) do
  def add(service) # steep:ignore
    self.inserted += service.inserted_count # steep:ignore
  end
end
```
