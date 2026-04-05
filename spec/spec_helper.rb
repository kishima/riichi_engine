require "bundler/setup"
require "pathname"
require "rspec/core"
require "rspec/expectations"
require "rspec/mocks"

require_relative "../lib/riichi_engine"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |file| require file }

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  root = Pathname(__dir__).join("..").expand_path
  config.example_status_persistence_file_path = root.join(".rspec_status").to_s
end
