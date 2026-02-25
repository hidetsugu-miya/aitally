module ClaudeCollector
  class ModelUsage < ClaudeCollectorRecord
    self.table_name = "model_usages"

    belongs_to :session,
               class_name: "ClaudeCollector::Session",
               inverse_of: :model_usages
  end
end
