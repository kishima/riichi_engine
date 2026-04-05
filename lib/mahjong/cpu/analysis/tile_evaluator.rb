module Mahjong
  module Cpu
    module Analysis
      EvalResult = Data.define(:tile, :shanten, :ukeire)

      class TileEvaluator
        def self.evaluate_all_discards(hand, visible_tiles: [])
          results = {}
          remaining = build_remaining_counts(visible_tiles + hand.tiles)

          hand.tiles.map(&:to_s).uniq.each do |tile_str|
            new_hand = hand.remove(Tiles::Tile.new(tile_str))
            tiles_34 = new_hand.to_34
            shanten = Shanten.calculate(tiles_34)
            ukeire = count_ukeire(tiles_34, shanten, remaining)

            results[tile_str] = EvalResult.new(
              tile: tile_str,
              shanten: shanten,
              ukeire: ukeire
            )
          end

          results
        end

        def self.count_ukeire(tiles_34, current_shanten, remaining)
          count = 0

          34.times do |i|
            next if tiles_34[i] >= 4
            next if remaining[i] <= 0

            tiles_34[i] += 1
            count += remaining[i] if Shanten.calculate(tiles_34) < current_shanten
            tiles_34[i] -= 1
          end

          count
        end

        def self.build_remaining_counts(visible_tiles)
          counts = Array.new(34, 4)

          visible_tiles.each do |tile|
            counts[Tiles::TileSet.tile_index(tile)] -= 1
          end

          counts
        end
      end
    end
  end
end
