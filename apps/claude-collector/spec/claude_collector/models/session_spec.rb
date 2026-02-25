# frozen_string_literal: true

RSpec.describe(ClaudeCollector::Models::Session) do
  describe 'associations' do
    it 'has many model_usages with dependent destroy', :aggregate_failures do
      session = described_class.create!(session_id: 'sess-assoc', project_path: '/tmp')
      session.model_usages.create!(model_id: 'claude-opus-4')

      expect(session.model_usages.count).to(eq(1))

      session.destroy!
      expect(ClaudeCollector::Models::ModelUsage.where(session_id: session.id).count).to(eq(0))
    end
  end
end
