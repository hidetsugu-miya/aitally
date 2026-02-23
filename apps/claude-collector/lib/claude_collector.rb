# frozen_string_literal: true

require "active_record"

require_relative "claude_collector/models/session"
require_relative "claude_collector/models/model_usage"
require_relative "claude_collector/parser"
require_relative "claude_collector/repository"
require_relative "claude_collector/watcher"

module ClaudeCollector
  def self.run
    database_url = ENV.fetch("DATABASE_URL")
    json_path = ENV.fetch("CLAUDE_JSON_PATH")

    ActiveRecord::Base.establish_connection(database_url)
    ActiveRecord::Base.logger = Logger.new($stdout, level: :warn)

    puts "[claude-collector] Connected to database."

    parser = Parser.new
    repository = Repository.new
    watcher = Watcher.new(json_path, parser: parser, repository: repository)

    shutdown = proc do
      puts "\n[claude-collector] Shutting down..."
      watcher.stop
      ActiveRecord::Base.connection_handler.clear_all_connections!
      exit(0)
    end

    Signal.trap("TERM", &shutdown)
    Signal.trap("INT", &shutdown)

    watcher.start
    sleep
  end
end
