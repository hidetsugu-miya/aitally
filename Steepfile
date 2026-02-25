# frozen_string_literal: true

# NOTE: エディタ（Zed/VSCode）のモノレポ対応用。
# CI での型チェックは各 app の Steepfile を使用する（make steep）。

D = Steep::Diagnostic

target :claude_collector do
  signature 'apps/claude-collector/sig/generated'
  signature 'apps/claude-collector/sig/shim'
  collection_config 'apps/claude-collector/rbs_collection.yaml'

  check 'apps/claude-collector/lib'

  configure_code_diagnostics(D::Ruby.default) do |config|
    config[D::Ruby::UnannotatedEmptyCollection] = nil
    config[D::Ruby::BlockTypeMismatch] = nil
  end
end

target :rails_app do
  signature 'apps/rails/sig/generated'
  signature 'apps/rails/sig/shim'
  collection_config 'apps/rails/rbs_collection.yaml'

  check 'apps/rails/app'
  check 'apps/rails/lib'

  configure_code_diagnostics(D::Ruby.default) do |config|
    config[D::Ruby::UnannotatedEmptyCollection] = nil
  end
end
