module Mahjong
  module Cpu
    module Analysis
      class Shanten
      def self.calculate(tiles_34)
        [
          regular_shanten(tiles_34.dup),
          chiitoitsu_shanten(tiles_34),
          kokushi_shanten(tiles_34)
        ].min
      end

      def self.regular_shanten(tiles_34)
        @min_shanten = 8
        explore(tiles_34, 0, 0, 0, 0)
        @min_shanten
      end

      def self.chiitoitsu_shanten(tiles_34)
        pairs = tiles_34.count { |count| count >= 2 }
        kinds = tiles_34.count(&:positive?)

        shanten = 6 - pairs
        shanten += [7 - kinds, 0].max if kinds < 7
        shanten
      end

      def self.kokushi_shanten(tiles_34)
        kinds = Tiles::TileSet::YAOCHU_INDICES.count { |i| tiles_34[i].positive? }
        pairs = Tiles::TileSet::YAOCHU_INDICES.count { |i| tiles_34[i] >= 2 }

        13 - kinds - (pairs.positive? ? 1 : 0)
      end

      def self.explore(tiles_34, index, mentsu, taatsu, pair)
        while index < 34 && tiles_34[index].zero?
          index += 1
        end

        if index >= 34
          taatsu = [taatsu, 4 - mentsu].min
          shanten = 8 - (mentsu * 2) - taatsu - pair
          @min_shanten = [@min_shanten, shanten].min
          return
        end

        if tiles_34[index] >= 3
          tiles_34[index] -= 3
          explore(tiles_34, index, mentsu + 1, taatsu, pair)
          tiles_34[index] += 3
        end

        if sequence_start?(tiles_34, index)
          tiles_34[index] -= 1
          tiles_34[index + 1] -= 1
          tiles_34[index + 2] -= 1
          explore(tiles_34, index, mentsu + 1, taatsu, pair)
          tiles_34[index] += 1
          tiles_34[index + 1] += 1
          tiles_34[index + 2] += 1
        end

        if pair.zero? && tiles_34[index] >= 2
          tiles_34[index] -= 2
          explore(tiles_34, index, mentsu, taatsu, 1)
          tiles_34[index] += 2
        end

        if taatsu < 4
          if tiles_34[index] >= 2
            tiles_34[index] -= 2
            explore(tiles_34, index, mentsu, taatsu + 1, pair)
            tiles_34[index] += 2
          end

          if iipeikou_wait?(tiles_34, index)
            tiles_34[index] -= 1
            tiles_34[index + 1] -= 1
            explore(tiles_34, index, mentsu, taatsu + 1, pair)
            tiles_34[index] += 1
            tiles_34[index + 1] += 1
          end

          if kanchan_wait?(tiles_34, index)
            tiles_34[index] -= 1
            tiles_34[index + 2] -= 1
            explore(tiles_34, index, mentsu, taatsu + 1, pair)
            tiles_34[index] += 1
            tiles_34[index + 2] += 1
          end
        end

        tiles_34[index] -= 1
        explore(tiles_34, index, mentsu, taatsu, pair)
        tiles_34[index] += 1
      end

      def self.sequence_start?(tiles_34, index)
        index < 27 && (index % 9) <= 6 && tiles_34[index + 1].positive? && tiles_34[index + 2].positive?
      end

      def self.iipeikou_wait?(tiles_34, index)
        index < 27 && (index % 9) <= 7 && tiles_34[index + 1].positive?
      end

      def self.kanchan_wait?(tiles_34, index)
        index < 27 && (index % 9) <= 6 && tiles_34[index + 2].positive?
      end
      end
    end
  end
end
