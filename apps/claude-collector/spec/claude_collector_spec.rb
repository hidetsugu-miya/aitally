# frozen_string_literal: true

RSpec.describe ClaudeCollector do
  describe '.run' do
    let(:watcher) { instance_double(ClaudeCollector::Watcher, start: nil, stop: nil) }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('DATABASE_URL').and_return('sqlite3::memory:')
      allow(ENV).to receive(:fetch).with('CLAUDE_JSON_PATH').and_return('/tmp/claude.json')
      allow(ActiveRecord::Base).to receive(:establish_connection)
      allow(ActiveRecord::Base).to receive(:logger=)
      allow(ClaudeCollector::Watcher).to receive(:new).and_return(watcher)
      allow(described_class).to receive(:puts)
    end

    it 'establishes database connection and starts watcher' do
      allow(Signal).to receive(:trap)
      allow(described_class).to receive(:sleep).and_raise(Interrupt)

      expect { described_class.run }.to raise_error(Interrupt)

      expect(ActiveRecord::Base).to have_received(:establish_connection).with('sqlite3::memory:')
      expect(ClaudeCollector::Watcher).to have_received(:new).with(
        '/tmp/claude.json',
        parser: an_instance_of(ClaudeCollector::Parser),
        repository: an_instance_of(ClaudeCollector::Repository)
      )
      expect(watcher).to have_received(:start)
    end

    it 'registers signal traps and calls sleep' do
      allow(Signal).to receive(:trap)
      allow(described_class).to receive(:sleep).and_raise(Interrupt)

      expect { described_class.run }.to raise_error(Interrupt)

      expect(Signal).to have_received(:trap).with('TERM')
      expect(Signal).to have_received(:trap).with('INT')
      expect(described_class).to have_received(:sleep)
    end

    it 'shutdown proc stops watcher, clears connections, and exits' do
      shutdown_proc = nil
      allow(Signal).to receive(:trap) do |_signal, &block|
        shutdown_proc = block
      end
      allow(described_class).to receive(:sleep).and_raise(Interrupt)

      expect { described_class.run }.to raise_error(Interrupt)

      allow(ActiveRecord::Base.connection_handler).to receive(:clear_all_connections!)

      expect { shutdown_proc.call }.to raise_error(SystemExit)
      expect(watcher).to have_received(:stop)
      expect(ActiveRecord::Base.connection_handler).to have_received(:clear_all_connections!)
    end
  end

  describe '.run integration' do
    let(:fixture_path) { File.expand_path('fixtures/claude.json', __dir__) }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('DATABASE_URL').and_return('sqlite3::memory:')
      allow(ENV).to receive(:fetch).with('CLAUDE_JSON_PATH').and_return(fixture_path)
      # Use real DB connection already established by spec_helper
      allow(ActiveRecord::Base).to receive(:establish_connection)
      allow(ActiveRecord::Base).to receive(:logger=)
      allow(Signal).to receive(:trap)
      allow(Listen).to receive(:to).and_return(instance_double(Listen::Listener, start: nil))
      allow(described_class).to receive(:sleep).and_raise(Interrupt)
      allow(described_class).to receive(:puts)
    end

    it 'parses fixture JSON and saves sessions to database' do
      expect { described_class.run }.to raise_error(Interrupt)

      session = ClaudeCollector::Models::Session.find_by(session_id: 'sess-001')
      expect(session).not_to be_nil
      expect(session.project_path).to eq('/home/user/project-a')
      expect(session.cost_usd).to eq(0.123456)
      expect(session.total_input_tokens).to eq(10_000)
      expect(session.total_output_tokens).to eq(5_000)
      expect(session.duration_ms).to eq(60_000)

      usages = session.model_usages.order(:model_id)
      expect(usages.size).to eq(2)
      expect(usages.first.model_id).to eq('claude-haiku-3.5')
      expect(usages.last.model_id).to eq('claude-opus-4')
      expect(usages.last.input_tokens).to eq(8_000)
    end

    it 'skips projects without session_id' do
      expect { described_class.run }.to raise_error(Interrupt)

      expect(ClaudeCollector::Models::Session.count).to eq(1)
    end
  end
end
