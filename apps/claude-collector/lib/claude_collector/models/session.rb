# frozen_string_literal: true

module ClaudeCollector
  module Models
    class Session < ActiveRecord::Base
      has_many :model_usages, dependent: :destroy
    end
  end
end
