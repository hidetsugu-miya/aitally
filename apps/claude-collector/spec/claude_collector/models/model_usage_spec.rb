# frozen_string_literal: true

RSpec.describe ClaudeCollector::Models::ModelUsage do
  describe 'associations' do
    it 'belongs to session' do
      session = ClaudeCollector::Models::Session.create!(session_id: 'sess-mu', project_path: '/tmp')
      usage = described_class.create!(session: session, model_id: 'claude-opus-4')

      expect(usage.session).to eq(session)
    end
  end
end
