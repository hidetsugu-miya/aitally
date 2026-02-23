# frozen_string_literal: true

# rbs_inline: enabled

module ClaudeCollector
  class Repository
    # @rbs return: Set[String]
    def known_session_ids
      Models::Session.pluck(:session_id).to_set
    end

    # @rbs sessions: Array[Hash[Symbol, Object]]
    # @rbs return: Integer
    def save(sessions)
      known = known_session_ids
      new_sessions = sessions.reject do |s|
        # @type var session_id: String
        session_id = s[:session_id]
        known.include?(session_id)
      end
      return 0 if new_sessions.empty?

      saved = 0
      new_sessions.each do |session_data|
        saved += 1 if save_session(session_data)
      end
      saved
    end

    private

    # @rbs session_data: Hash[Symbol, Object]
    # @rbs return: bool
    def save_session(session_data)
      ActiveRecord::Base.transaction do
        # @type var model_usages_data: Array[Hash[Symbol, Object]]
        model_usages_data = session_data[:model_usages] || []
        session = Models::Session.create!(session_data.except(:model_usages))
        model_usages_data.each do |usage_data|
          session.model_usages.create!(usage_data)
        end
      end
      true
    rescue ActiveRecord::RecordNotUnique
      # Another process already inserted this session — skip
      false
    end
  end
end
