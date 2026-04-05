Gem::Specification.new do |spec|
  spec.name = "riichi_engine"
  spec.version = "0.1.0"
  spec.summary = "Pure Ruby Mahjong domain logic for the app"
  spec.authors = ["OpenAI Codex"]
  spec.license = "MIT"
  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*.rb"] + Dir["spec/**/*.rb"] + Dir["docs/**/*.md"] + Dir[".github/**/*"] + ["README.md", "CHANGELOG.md", "LICENSE", "Gemfile", ".gitignore", ".ruby-version", "riichi_engine.gemspec"]
  end
  spec.require_paths = ["lib"]
  spec.add_dependency "zeitwerk"
  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "rspec-expectations"
  spec.add_development_dependency "rspec-mocks"
end
