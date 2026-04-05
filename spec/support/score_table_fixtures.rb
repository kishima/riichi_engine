unless defined?(ScoreTableFixtures)
module ScoreTableFixtures
  KO_RON_TABLE = [
    [30, 1, 1000],
    [30, 2, 2000],
    [30, 3, 3900],
    [30, 4, 7700],
    [40, 1, 1300],
    [40, 2, 2600],
    [40, 3, 5200],
    [50, 1, 1600],
    [50, 2, 3200],
    [50, 3, 6400],
    [60, 1, 2000],
    [60, 2, 3900],
    [25, 2, 1600],
    [25, 3, 3200],
    [25, 4, 6400]
  ].freeze

  OYA_RON_TABLE = [
    [30, 1, 1500],
    [30, 2, 2900],
    [30, 3, 5800],
    [30, 4, 11600],
    [40, 1, 2000],
    [40, 2, 3900],
    [40, 3, 7700]
  ].freeze

  LIMIT_HANDS = [
    [5, false, :ron, { ron_pay: 8000 }],
    [5, true, :ron, { ron_pay: 12000 }],
    [5, false, :tsumo, { ko_pays: 1000, oya_pays: 2000 }],
    [5, true, :tsumo, { ko_pays: 4000 }],
    [6, false, :ron, { ron_pay: 12000 }],
    [8, false, :ron, { ron_pay: 16000 }],
    [11, false, :ron, { ron_pay: 24000 }],
    [13, false, :ron, { ron_pay: 32000 }]
  ].freeze
end

RSpec.configure do |config|
  config.include ScoreTableFixtures
end
end
