# frozen_string_literal: true

# rbs_inline: enabled

require 'rails_helper'

RSpec.describe(ClaudeCollector::ModelUsage) do
  describe '.table_name' do
    it 'model_usagesテーブルを参照する' do
      expect(described_class.table_name).to(eq('model_usages'))
    end
  end

  describe 'アソシエーション' do
    let(:association) { described_class.reflect_on_association(:session) }

    it 'sessionに所属する' do
      expect(association.macro).to(eq(:belongs_to))
    end

    it 'sessionのclass_nameが正しい' do
      expect(association.options[:class_name]).to(eq('ClaudeCollector::Session'))
    end

    it 'sessionのinverse_ofが正しい' do
      expect(association.options[:inverse_of]).to(eq(:model_usages))
    end
  end
end
