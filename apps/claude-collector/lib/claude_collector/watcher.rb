# frozen_string_literal: true

# rbs_inline: enabled

require 'listen'

module ClaudeCollector
  class Watcher
    # @rbs @path: String
    # @rbs @parser: Parser
    # @rbs @repository: Repository
    # @rbs @listener: Listen::Listener?

    # @rbs path: String
    # @rbs parser: Parser
    # @rbs repository: Repository
    # @rbs return: void
    def initialize(path, parser:, repository:)
      @path = path
      @parser = parser
      @repository = repository
    end

    # @rbs return: void
    def start
      collect('initial')

      dir = File.dirname(@path)
      filename = File.basename(@path)

      listener = Listen.to(dir, only: /\A#{Regexp.escape(filename)}\z/,
                                force_polling: polling?) do |modified, added, _removed|
        collect('change') if (modified + added).any? { |f| File.basename(f) == filename }
      end

      listener.start
      @listener = listener
      puts "[claude-collector] Watching #{@path} (polling=#{polling?})"
    end

    # @rbs return: void
    def stop
      @listener&.stop
      puts '[claude-collector] Stopped watching.'
    end

    private

    # @rbs return: bool
    def polling?
      ENV['LISTEN_POLLING'] == 'true'
    end

    # @rbs trigger: String
    # @rbs return: void
    def collect(trigger)
      sessions = @parser.parse(@path)
      saved = @repository.save(sessions)
      puts "[claude-collector] [#{trigger}] Parsed #{sessions.size} projects, saved #{saved} new sessions."
    rescue StandardError => e
      warn "[claude-collector] Error during collect (#{trigger}): #{e.message}"
    end
  end
end
