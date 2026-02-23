# frozen_string_literal: true

# rbs_inline: enabled

require 'active_record'

require_relative 'claude_collector/models/session'
require_relative 'claude_collector/models/model_usage'
require_relative 'claude_collector/parser'
require_relative 'claude_collector/repository'
require_relative 'claude_collector/watcher'

module ClaudeCollector
  # @rbs () -> void
  def self.run
    database_url = ENV.fetch('DATABASE_URL')
    json_path = ENV.fetch('CLAUDE_JSON_PATH')

    setup_database(database_url)

    parser = Parser.new
    repository = Repository.new
    watcher = Watcher.new(json_path, parser: parser, repository: repository)

    shutdown = proc do
      puts "\n[claude-collector] Shutting down..."
      watcher.stop
      ActiveRecord::Base.connection_handler.clear_all_connections!
      exit(0)
    end

    setup_signal_traps(shutdown)

    watcher.start
    sleep
  end

  class << self
    private

    # @rbs (String database_url) -> void
    def setup_database(database_url)
      ActiveRecord::Base.establish_connection(database_url)
      ActiveRecord::Base.logger = Logger.new($stdout, level: :warn)
      puts '[claude-collector] Connected to database.'
    end

    # @rbs (Proc shutdown) -> void
    def setup_signal_traps(shutdown)
      Signal.trap('TERM', &shutdown)
      Signal.trap('INT', &shutdown)
    end
  end
end
