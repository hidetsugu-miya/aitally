# frozen_string_literal: true

# rbs_inline: enabled

module ClaudeCollector
  module Models
    class ModelUsage < ApplicationRecord
      # @rbs!
      #   def self.create!: (Hash[Symbol, Object]) -> ModelUsage

      belongs_to :session
    end
  end
end
