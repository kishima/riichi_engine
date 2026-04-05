module Mahjong
  module Scoring
    module Judges
      class FuritenJudge
      def self.judge(state:, seat:)
        hand = state.hands[seat]
        kawa = state.kawas[seat]
        tiles_34 = hand.to_34

        machi_indices = MachiJudge.machi_tile_indices(tiles_34)
        return FuritenResult.new(furiten: false, type: nil) if machi_indices.empty?

        machi_tiles = machi_indices.map { |i| Tiles::Tile.new(Tiles::TileSet.from_index(i)) }
        return FuritenResult.new(furiten: true, type: :normal) if machi_tiles.any? { |mt| kawa.includes_kind?(mt) }
        return FuritenResult.new(furiten: true, type: :dojun) if state.respond_to?(:dojun_furiten_flags) && state.dojun_furiten_flags[seat]

        if state.riichi_flags[seat] &&
           state.respond_to?(:riichi_furiten_flags) &&
           state.riichi_furiten_flags[seat]
          return FuritenResult.new(furiten: true, type: :riichi)
        end

        FuritenResult.new(furiten: false, type: nil)
      end
    end

    FuritenResult = Data.define(:furiten, :type) do
      def furiten?
        furiten
      end
      end
    end
  end
end
