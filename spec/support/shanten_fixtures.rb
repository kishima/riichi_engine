unless defined?(ShantenFixtures)
module ShantenFixtures
  SHANTEN_CASES = [
    ["1m 2m 3m 4p 5p 6p 7s 8s 9s 1z 1z 1z 2z 2z", -1, "和了形"],
    ["1m 2m 3m 4p 5p 6p 7s 8s 9s 1z 1z 1z 2z", 0, "テンパイ"],
    ["1m 2m 3m 4p 5p 6p 7s 8s 1z 1z 1z 2z 5z", 1, "イーシャンテン"],
    ["1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z", 0, "国士テンパイ"],
    ["1m 1m 3m 3m 5p 5p 7p 7p 9s 9s 1z 1z 3z", 0, "七対子テンパイ"],
    ["1m 3m 5m 7m 2p 4p 6p 8p 1s 3s 5s 7s 9s", 6, "バラバラ"]
  ].freeze
end

RSpec.configure do |config|
  config.include ShantenFixtures
end
end
