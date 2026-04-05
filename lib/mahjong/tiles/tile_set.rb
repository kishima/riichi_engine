module Mahjong
  module Tiles
    class TileSet
      YAOCHU_INDICES = [0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33].freeze

      def self.to_34(tiles)
        counts = Array.new(34, 0)
        tiles.each { |t| counts[tile_index(t)] += 1 }
        counts
      end

      def self.tile_index(tile)
        num = tile.effective_number
        case tile.suit
        when "m" then num - 1
        when "p" then num + 8
        when "s" then num + 17
        when "z" then num + 26
        end
      end

      def self.from_index(idx)
        case idx
        when 0..8   then "#{idx + 1}m"
        when 9..17  then "#{idx - 8}p"
        when 18..26 then "#{idx - 17}s"
        when 27..33 then "#{idx - 26}z"
        end
      end

      def self.sort(tiles)
        tiles.sort
      end

      def self.count_same(tiles, target)
        tiles.count { |t| t.same_kind?(target) }
      end

      def self.remove_one(tiles, target)
        idx = tiles.index { |t| t.same_kind?(target) }
        return tiles.dup unless idx

        tiles.dup.tap { |a| a.delete_at(idx) }
      end

      def self.yaochu_kind_count(tiles)
        tiles.select(&:yaochu?).map { |t| [t.suit, t.effective_number] }.uniq.count
      end
    end
  end
end
