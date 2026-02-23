# frozen_string_literal: true

RSpec.describe ClaudeCollector::Repository do
  subject(:repository) { described_class.new }

  let(:session_data) do
    {
      session_id: 'sess-repo-001',
      project_path: '/home/user/project',
      cost_usd: 0.05,
      total_input_tokens: 1000,
      total_output_tokens: 500,
      total_cache_creation_input_tokens: nil,
      total_cache_read_input_tokens: nil,
      total_web_search_requests: nil,
      duration_ms: 30_000,
      api_duration_ms: 20_000,
      lines_added: 10,
      lines_removed: 5,
      model_usages: [
        {
          model_id: 'claude-opus-4',
          input_tokens: 1000,
          output_tokens: 500,
          cache_read_input_tokens: nil,
          cache_creation_input_tokens: nil,
          web_search_requests: nil,
          cost_usd: 0.05
        }
      ]
    }
  end

  describe '#known_session_ids' do
    it 'returns a set of existing session_ids' do
      ClaudeCollector::Models::Session.create!(session_id: 'sess-known', project_path: '/tmp')

      expect(repository.known_session_ids).to include('sess-known')
    end

    it 'returns empty set when no sessions exist' do
      expect(repository.known_session_ids).to be_empty
    end
  end

  describe '#save' do
    it 'saves new sessions with model_usages' do
      saved = repository.save([session_data])

      expect(saved).to eq(1)
      expect(ClaudeCollector::Models::Session.count).to eq(1)
      expect(ClaudeCollector::Models::ModelUsage.count).to eq(1)

      session = ClaudeCollector::Models::Session.first
      expect(session.session_id).to eq('sess-repo-001')
      expect(session.model_usages.first.model_id).to eq('claude-opus-4')
    end

    it 'skips sessions already in known_session_ids' do
      ClaudeCollector::Models::Session.create!(session_id: 'sess-repo-001', project_path: '/tmp')

      saved = repository.save([session_data])

      expect(saved).to eq(0)
      expect(ClaudeCollector::Models::Session.count).to eq(1)
    end

    it 'handles RecordNotUnique by skipping' do
      repository.save([session_data])

      test_repo = described_class.new
      allow(test_repo).to receive(:known_session_ids).and_return(Set.new)

      saved = test_repo.save([session_data])
      expect(saved).to eq(0)
    end

    it 'returns 0 for empty array' do
      expect(repository.save([])).to eq(0)
    end
  end
end
