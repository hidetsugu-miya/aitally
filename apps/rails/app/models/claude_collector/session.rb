module ClaudeCollector
  class Session < ClaudeCollectorRecord
    self.table_name = "sessions"

    has_many :model_usages,
             class_name: "ClaudeCollector::ModelUsage",
             foreign_key: :session_id,
             inverse_of: :session,
             dependent: false
  end
end
