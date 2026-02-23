# frozen_string_literal: true

module ClaudeCollector
  module Models
    class ModelUsage < ActiveRecord::Base
      belongs_to :session
    end
  end
end
