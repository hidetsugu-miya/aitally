# frozen_string_literal: true

# rbs_inline: enabled

module ClaudeCollector
  class Session < ClaudeCollectorRecord
    self.table_name = 'sessions'

    has_many :model_usages,
             class_name: 'ClaudeCollector::ModelUsage',
             inverse_of: :session,
             dependent: false
  end
end
