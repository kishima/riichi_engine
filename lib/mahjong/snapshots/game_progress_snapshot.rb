module Mahjong
  module Snapshots
    GameProgressSnapshot = Data.define(
      :bakaze,
      :kyoku,
      :honba,
      :kyoutaku,
      :oya_index,
      :scores
    )
  end
end
