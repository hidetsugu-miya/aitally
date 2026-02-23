# frozen_string_literal: true

RSpec.describe ClaudeCollector::Watcher do
  let(:parser) { instance_double(ClaudeCollector::Parser) }
  let(:repository) { instance_double(ClaudeCollector::Repository) }
  let(:path) { "/tmp/claude.json" }
  subject(:watcher) { described_class.new(path, parser: parser, repository: repository) }

  before do
    allow(parser).to receive(:parse).and_return([])
    allow(repository).to receive(:save).and_return(0)
  end

  describe "#start" do
    let(:listener) { instance_double(Listen::Listener, start: nil) }

    before do
      allow(Listen).to receive(:to).and_return(listener)
      allow(watcher).to receive(:puts)
    end

    it "calls collect on initial start" do
      watcher.start

      expect(parser).to have_received(:parse).with(path)
      expect(repository).to have_received(:save)
    end

    it "sets up a file listener" do
      watcher.start

      expect(Listen).to have_received(:to).with(
        "/tmp",
        hash_including(:only, :force_polling)
      )
      expect(listener).to have_received(:start)
    end
  end

  describe "#stop" do
    let(:listener) { instance_double(Listen::Listener, start: nil, stop: nil) }

    before do
      allow(Listen).to receive(:to).and_return(listener)
      allow(watcher).to receive(:puts)
    end

    it "stops the listener" do
      watcher.start
      watcher.stop

      expect(listener).to have_received(:stop)
    end

    it "handles stop when listener is nil" do
      allow(watcher).to receive(:puts)
      expect { watcher.stop }.not_to raise_error
    end
  end

  describe "#collect (via start)" do
    let(:listener) { instance_double(Listen::Listener, start: nil) }

    before do
      allow(Listen).to receive(:to).and_return(listener)
      allow(watcher).to receive(:puts)
    end

    it "passes parsed sessions to repository.save" do
      sessions = [{ session_id: "sess-w1", project_path: "/tmp" }]
      allow(parser).to receive(:parse).and_return(sessions)
      allow(repository).to receive(:save).and_return(1)

      watcher.start

      expect(repository).to have_received(:save).with(sessions)
    end

    it "rescues and warns on error" do
      allow(parser).to receive(:parse).and_raise(StandardError.new("test error"))
      allow(watcher).to receive(:warn)

      watcher.start

      expect(watcher).to have_received(:warn).with(/test error/)
    end
  end

  describe "listener callback" do
    let(:listener) { instance_double(Listen::Listener, start: nil) }
    let(:callback) { nil }

    before do
      allow(Listen).to receive(:to) do |_dir, **_opts, &block|
        @callback = block
        listener
      end
      allow(watcher).to receive(:puts)
    end

    it "triggers collect when the watched file is modified" do
      watcher.start
      allow(parser).to receive(:parse).and_return([])
      allow(repository).to receive(:save).and_return(0)

      @callback.call(["/tmp/claude.json"], [], [])

      expect(parser).to have_received(:parse).with(path).twice
    end

    it "does not trigger collect when a different file changes" do
      watcher.start

      @callback.call(["/tmp/other.json"], [], [])

      expect(parser).to have_received(:parse).with(path).once
    end
  end

  describe "polling?" do
    let(:listener) { instance_double(Listen::Listener, start: nil) }

    before do
      allow(Listen).to receive(:to).and_return(listener)
      allow(watcher).to receive(:puts)
    end

    it "returns true when LISTEN_POLLING is 'true'" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("LISTEN_POLLING").and_return("true")

      watcher.start

      expect(Listen).to have_received(:to).with(anything, hash_including(force_polling: true))
    end

    it "returns false when LISTEN_POLLING is not set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("LISTEN_POLLING").and_return(nil)

      watcher.start

      expect(Listen).to have_received(:to).with(anything, hash_including(force_polling: false))
    end
  end
end
