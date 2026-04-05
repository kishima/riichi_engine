require_relative "lib/riichi_engine/version"

Gem::Specification.new do |spec|
  spec.name        = "riichi_engine"
  spec.version     = RiichiEngine::VERSION
  spec.summary     = "Pure Ruby riichi mahjong engine"
  spec.description = "Provides round progression, win detection, yaku evaluation, and score " \
                     "calculation for riichi mahjong, independent of Rails or ActiveRecord."
  spec.authors     = ["HenrikStephensen"]
  spec.homepage    = "https://github.com/HenrikStephensen/riichi_engine"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.metadata = {
    "source_code_uri" => "https://github.com/HenrikStephensen/riichi_engine",
    "changelog_uri"   => "https://github.com/HenrikStephensen/riichi_engine/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/HenrikStephensen/riichi_engine/issues"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb"] + Dir["docs/**/*.md"] + Dir[".github/**/*"] +
      ["README.md", "CHANGELOG.md", "LICENSE", "Gemfile", ".gitignore", ".ruby-version", "riichi_engine.gemspec"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "zeitwerk"

  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "rspec-expectations"
  spec.add_development_dependency "rspec-mocks"
end
