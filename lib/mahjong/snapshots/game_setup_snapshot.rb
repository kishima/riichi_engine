module Mahjong
  module Snapshots
    GameSetupSnapshot = Data.define(
      :bakaze,
      :kyoku,
      :honba,
      :kyoutaku,
      :oya_index,
      :scores
    )
  end
end
