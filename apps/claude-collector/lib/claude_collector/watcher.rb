# frozen_string_literal: true

require "listen"

module ClaudeCollector
  class Watcher
    def initialize(path, parser:, repository:)
      @path = path
      @parser = parser
      @repository = repository
    end

    def start
      collect("initial")

      dir = File.dirname(@path)
      filename = File.basename(@path)

      @listener = Listen.to(dir, only: /\A#{Regexp.escape(filename)}\z/, force_polling: polling?) do |modified, added, _removed|
        collect("change") if (modified + added).any? { |f| File.basename(f) == filename }
      end

      @listener.start
      puts "[claude-collector] Watching #{@path} (polling=#{polling?})"
    end

    def stop
      @listener&.stop
      puts "[claude-collector] Stopped watching."
    end

    private

    def polling?
      ENV["LISTEN_POLLING"] == "true"
    end

    def collect(trigger)
      sessions = @parser.parse(@path)
      saved = @repository.save(sessions)
      puts "[claude-collector] [#{trigger}] Parsed #{sessions.size} projects, saved #{saved} new sessions."
    rescue => e
      warn "[claude-collector] Error during collect (#{trigger}): #{e.message}"
    end
  end
end
