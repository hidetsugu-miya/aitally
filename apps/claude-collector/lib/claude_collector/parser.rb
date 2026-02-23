# frozen_string_literal: true

require "json"

module ClaudeCollector
  class Parser
    MAX_RETRIES = 3
    RETRY_DELAY = 0.3

    def parse(path)
      data = read_json(path)
      return [] unless data.is_a?(Hash) && data["projects"].is_a?(Hash)

      data["projects"].filter_map do |project_path, project|
        session_id = project["lastSessionId"]
        next unless session_id

        {
          session_id: session_id,
          project_path: project_path,
          cost_usd: project["lastCost"],
          total_input_tokens: project["lastTotalInputTokens"],
          total_output_tokens: project["lastTotalOutputTokens"],
          total_cache_creation_input_tokens: project["lastTotalCacheCreationInputTokens"],
          total_cache_read_input_tokens: project["lastTotalCacheReadInputTokens"],
          total_web_search_requests: project["lastTotalWebSearchRequests"],
          duration_ms: project["lastDuration"],
          api_duration_ms: project["lastAPIDuration"],
          lines_added: project["lastLinesAdded"],
          lines_removed: project["lastLinesRemoved"],
          model_usages: parse_model_usages(project["lastModelUsage"])
        }
      end
    end

    private

    def read_json(path)
      retries = 0
      begin
        JSON.parse(File.read(path))
      rescue JSON::ParserError => e
        retries += 1
        if retries <= MAX_RETRIES
          sleep(RETRY_DELAY)
          retry
        end
        warn "[claude-collector] JSON parse failed after #{MAX_RETRIES} retries: #{e.message}"
        nil
      end
    end

    def parse_model_usages(model_usage_hash)
      return [] unless model_usage_hash.is_a?(Hash)

      model_usage_hash.map do |model_id, usage|
        {
          model_id: model_id,
          input_tokens: usage["inputTokens"],
          output_tokens: usage["outputTokens"],
          cache_read_input_tokens: usage["cacheReadInputTokens"],
          cache_creation_input_tokens: usage["cacheCreationInputTokens"],
          web_search_requests: usage["webSearchRequests"],
          cost_usd: usage["costUSD"]
        }
      end
    end
  end
end
