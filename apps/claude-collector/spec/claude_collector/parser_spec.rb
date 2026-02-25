# frozen_string_literal: true

RSpec.describe(ClaudeCollector::Parser) do
  subject(:parser) { described_class.new }

  let(:fixture_path) { File.expand_path('../fixtures/claude.json', __dir__) }

  describe '#parse' do
    context 'with valid JSON fixture' do
      it 'returns sessions that have a session_id', :aggregate_failures do
        sessions = parser.parse(fixture_path)

        expect(sessions.size).to(eq(1))
        expect(sessions.first[:session_id]).to(eq('sess-001'))
        expect(sessions.first[:project_path]).to(eq('/home/user/project-a'))
      end

      it 'extracts all session fields', :aggregate_failures do
        session = parser.parse(fixture_path).first

        expect(session[:cost_usd]).to(eq(0.123456))
        expect(session[:total_input_tokens]).to(eq(10_000))
        expect(session[:total_output_tokens]).to(eq(5_000))
        expect(session[:total_cache_creation_input_tokens]).to(eq(2_000))
        expect(session[:total_cache_read_input_tokens]).to(eq(3_000))
        expect(session[:total_web_search_requests]).to(eq(1))
        expect(session[:duration_ms]).to(eq(60_000))
        expect(session[:api_duration_ms]).to(eq(45_000))
        expect(session[:lines_added]).to(eq(100))
        expect(session[:lines_removed]).to(eq(20))
      end

      it 'parses model_usages for each session', :aggregate_failures do
        usages = parser.parse(fixture_path).first[:model_usages]

        expect(usages.size).to(eq(2))

        opus = usages.find { |u| u[:model_id] == 'claude-opus-4' }
        expect(opus[:input_tokens]).to(eq(8_000))
        expect(opus[:output_tokens]).to(eq(4_000))
        expect(opus[:cache_read_input_tokens]).to(eq(3_000))
        expect(opus[:cache_creation_input_tokens]).to(eq(2_000))
        expect(opus[:web_search_requests]).to(eq(1))
        expect(opus[:cost_usd]).to(eq(0.1))

        haiku = usages.find { |u| u[:model_id] == 'claude-haiku-3.5' }
        expect(haiku[:input_tokens]).to(eq(2_000))
        expect(haiku[:output_tokens]).to(eq(1_000))
      end
    end

    context 'with invalid JSON' do
      it 'retries and returns empty array after max retries', :aggregate_failures do
        path = Tempfile.new(['invalid', '.json']).path
        File.write(path, 'not valid json{{{')
        test_parser = described_class.new
        allow(test_parser).to(receive(:sleep))

        sessions = test_parser.parse(path)

        expect(sessions).to(eq([]))
        expect(test_parser).to(have_received(:sleep).exactly(3).times)
      end
    end

    context 'when projects key is missing' do
      it 'returns empty array' do
        path = Tempfile.new(['no_projects', '.json']).path
        File.write(path, '{"other": "data"}')

        expect(parser.parse(path)).to(eq([]))
      end
    end

    context 'when projects is not a Hash' do
      it 'returns empty array' do
        path = Tempfile.new(['bad_projects', '.json']).path
        File.write(path, '{"projects": "string"}')

        expect(parser.parse(path)).to(eq([]))
      end
    end

    context 'when lastModelUsage is nil' do
      it 'returns empty model_usages array' do
        path = Tempfile.new(['no_mu', '.json']).path
        File.write(path, JSON.generate({
                                         'projects' => {
                                           '/tmp/p' => { 'lastSessionId' => 'sess-x', 'lastModelUsage' => nil }
                                         }
                                       }))

        session = parser.parse(path).first
        expect(session[:model_usages]).to(eq([]))
      end
    end
  end
end
