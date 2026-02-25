# frozen_string_literal: true

# rbs_inline: enabled

require 'json'

module ClaudeCollector
  class Parser
    MAX_RETRIES = 3 #: Integer
    RETRY_DELAY = 0.3 #: Float

    # @rbs path: String
    # @rbs return: Array[Hash[Symbol, Object]]
    def parse(path)
      data = read_json(path)
      return [] unless data.is_a?(Hash) && data['projects'].is_a?(Hash)

      data['projects'].filter_map do |project_path, project|
        build_session(project_path, project)
      end
    end

    private

    # @rbs project_path: String
    # @rbs project: Hash[String, Object]
    # @rbs return: Hash[Symbol, Object]?
    def build_session(project_path, project)
      session_id = project['lastSessionId']
      return unless session_id

      # @type var session_id: String

      base_attrs(project_path, session_id, project)
        .merge(token_attrs(project))
        .merge(model_usages: parse_model_usages(project['lastModelUsage']))
    end

    # @rbs project_path: String
    # @rbs session_id: String
    # @rbs project: Hash[String, Object]
    # @rbs return: Hash[Symbol, Object]
    def base_attrs(project_path, session_id, project)
      {
        session_id:,
        project_path:,
        cost_usd: project['lastCost'],
        duration_ms: project['lastDuration'],
        api_duration_ms: project['lastAPIDuration'],
        lines_added: project['lastLinesAdded'],
        lines_removed: project['lastLinesRemoved']
      }
    end

    # @rbs project: Hash[String, Object]
    # @rbs return: Hash[Symbol, Object]
    def token_attrs(project)
      {
        total_input_tokens: project['lastTotalInputTokens'],
        total_output_tokens: project['lastTotalOutputTokens'],
        total_cache_creation_input_tokens: project['lastTotalCacheCreationInputTokens'],
        total_cache_read_input_tokens: project['lastTotalCacheReadInputTokens'],
        total_web_search_requests: project['lastTotalWebSearchRequests']
      }
    end

    # @rbs path: String
    # @rbs return: Hash[String, Object]?
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
        warn("[claude-collector] JSON parse failed after #{MAX_RETRIES} retries: #{e.message}")
        nil
      end
    end

    # @rbs model_usage_hash: Object
    # @rbs return: Array[Hash[Symbol, Object]]
    def parse_model_usages(model_usage_hash)
      return [] unless model_usage_hash.is_a?(Hash)

      model_usage_hash.map do |model_id, usage|
        {
          model_id:,
          input_tokens: usage['inputTokens'],
          output_tokens: usage['outputTokens'],
          cache_read_input_tokens: usage['cacheReadInputTokens'],
          cache_creation_input_tokens: usage['cacheCreationInputTokens'],
          web_search_requests: usage['webSearchRequests'],
          cost_usd: usage['costUSD']
        }
      end
    end
  end
end
