# frozen_string_literal: true

# rbs_inline: enabled

require 'rails_helper'

RSpec.describe(ClaudeCollectorRecord) do
  describe '.abstract_class' do
    it '抽象クラスである' do
      expect(described_class).to(be_abstract_class)
    end
  end

  describe 'データベース接続設定' do
    it 'claude_collectorデータベースに接続する' do
      expect(described_class.connection_db_config.name).to(eq('claude_collector'))
    end
  end

  describe 'readonly設定' do
    it 'persisted?レコードに対してreadonly!が設定される' do
      callbacks = described_class._initialize_callbacks.select { |cb| cb.filter == :readonly! }
      expect(callbacks).not_to(be_empty)
    end
  end
end
