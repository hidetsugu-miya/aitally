# frozen_string_literal: true

# rbs_inline: enabled

require 'simplecov'
SimpleCov.start('rails') do
  enable_coverage(:branch)
  minimum_coverage(line: 100, branch: 100)
  add_filter('/spec/')
  add_filter('app/controllers/application_controller.rb')
  add_filter('app/jobs/application_job.rb')
  add_filter('app/models/application_record.rb')
end

RSpec.configure do |config|
  config.expect_with(:rspec) do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching(:focus)
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand(config.seed)
end
