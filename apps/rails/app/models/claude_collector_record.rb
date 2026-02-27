# frozen_string_literal: true

# rbs_inline: enabled

class ClaudeCollectorRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :claude_collector, reading: :claude_collector }

  after_initialize :readonly!, if: :persisted?
end
