require "json"
require "zeitwerk"
require_relative "riichi_engine/version"

module RiichiEngine
  def self.loader
    @loader ||= Zeitwerk::Loader.new.tap do |loader|
      loader.tag = "riichi_engine"
      loader.inflector.inflect("api" => "API")
      loader.ignore("#{__dir__}/riichi_engine/version.rb")
      loader.push_dir(__dir__)
      loader.setup
    end
  end
end

RiichiEngine.loader
require_relative "riichi_engine/api"
