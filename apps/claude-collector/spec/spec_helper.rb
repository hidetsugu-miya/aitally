# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
  add_filter '/spec/'
  add_filter '/db/migrations/'
end

require 'active_record'
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Migration.verbose = false
ActiveRecord::MigrationContext.new(File.expand_path('../db/migrations', __dir__)).migrate

require 'tempfile'
require_relative '../lib/claude_collector'

RSpec.configure do |config|
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
