require "json"
require "zeitwerk"

module RiichiEngine
  def self.loader
    @loader ||= Zeitwerk::Loader.new.tap do |loader|
      loader.tag = "riichi_engine"
      loader.push_dir(__dir__)
      loader.setup
    end
  end
end

RiichiEngine.loader
require_relative "riichi_engine/api"
