# frozen_string_literal: true

module ClaudeCollector
  class Repository
    def known_session_ids
      Models::Session.pluck(:session_id).to_set
    end

    def save(sessions)
      known = known_session_ids
      new_sessions = sessions.reject { |s| known.include?(s[:session_id]) }
      return 0 if new_sessions.empty?

      saved = 0
      new_sessions.each do |session_data|
        saved += 1 if save_session(session_data)
      end
      saved
    end

    private

    def save_session(session_data)
      ActiveRecord::Base.transaction do
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
