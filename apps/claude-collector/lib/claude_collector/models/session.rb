# frozen_string_literal: true

# rbs_inline: enabled

module ClaudeCollector
  module Models
    class Session < ActiveRecord::Base
      # @rbs!
      #   def self.pluck: (*Symbol) -> Array[String]
      #   def self.create!: (Hash[Symbol, Object]) -> Session
      #   def model_usages: () -> ActiveRecord::Associations::CollectionProxy

      has_many :model_usages, dependent: :destroy
    end
  end
end
