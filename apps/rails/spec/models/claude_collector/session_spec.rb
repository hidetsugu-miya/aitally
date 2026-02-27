# frozen_string_literal: true

# rbs_inline: enabled

require 'rails_helper'

RSpec.describe(ClaudeCollector::Session) do
  describe '.table_name' do
    it 'sessionsテーブルを参照する' do
      expect(described_class.table_name).to(eq('sessions'))
    end
  end

  describe 'アソシエーション' do
    let(:association) { described_class.reflect_on_association(:model_usages) }

    it 'model_usagesを複数持つ' do
      expect(association.macro).to(eq(:has_many))
    end

    it 'model_usagesのclass_nameが正しい' do
      expect(association.options[:class_name]).to(eq('ClaudeCollector::ModelUsage'))
    end

    it 'model_usagesのinverse_ofが正しい' do
      expect(association.options[:inverse_of]).to(eq(:session))
    end

    it 'model_usagesのdependentがfalseである' do
      expect(association.options[:dependent]).to(be(false))
    end
  end
end
