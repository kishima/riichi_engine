module Mahjong
  module Scoring
    module Parsers
      class HandParser
        # 手牌を全ての有効なメンツ分解パターンに分解する
        def self.parse(tiles_34)
          results = []
          work = tiles_34.dup

          34.times do |i|
            next unless work[i] >= 2

            work[i] -= 2
            find_mentsu(work, 0, [], results, i)
            work[i] += 2
          end

          results
        end

        private

        def self.find_mentsu(tiles_34, start, mentsu_list, results, jantou_index)
          if tiles_34.all?(&:zero?)
            results << ParsedHand.new(
              jantou_index: jantou_index,
              mentsu_indices: mentsu_list.dup
            )
            return
          end

          i = (start...34).find { |idx| tiles_34[idx] > 0 }
          return unless i

          if tiles_34[i] >= 3
            tiles_34[i] -= 3
            mentsu_list << { type: :koutsu, index: i }
            find_mentsu(tiles_34, i, mentsu_list, results, jantou_index)
            mentsu_list.pop
            tiles_34[i] += 3
          end

          if i < 27 && (i % 9) <= 6
            if tiles_34[i] > 0 && tiles_34[i + 1] > 0 && tiles_34[i + 2] > 0
              tiles_34[i] -= 1
              tiles_34[i + 1] -= 1
              tiles_34[i + 2] -= 1
              mentsu_list << { type: :shuntsu, index: i }
              find_mentsu(tiles_34, i, mentsu_list, results, jantou_index)
              mentsu_list.pop
              tiles_34[i] += 1
              tiles_34[i + 1] += 1
              tiles_34[i + 2] += 1
            end
          end
        end
      end

      class ParsedHand
        attr_reader :jantou_index, :mentsu_indices

        def initialize(jantou_index:, mentsu_indices:)
          @jantou_index = jantou_index
          @mentsu_indices = mentsu_indices.freeze
          freeze
        end

        def jantou_notation
          Tiles::TileSet.from_index(jantou_index)
        end

        def mentsu_notations
          mentsu_indices.map do |m|
            case m[:type]
            when :shuntsu
              tiles = (0..2).map { |d| Tiles::TileSet.from_index(m[:index] + d) }
              { type: :shuntsu, tiles: tiles }
            when :koutsu
              tile = Tiles::TileSet.from_index(m[:index])
              { type: :koutsu, tiles: [tile, tile, tile] }
            end
          end
        end
      end
    end
  end
end
