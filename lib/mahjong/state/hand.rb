module Mahjong
  module State
    class Hand
      attr_reader :tiles

      def initialize(tiles = [])
        @tiles = tiles.map { |t| t.is_a?(Tiles::Tile) ? t : Tiles::Tile.new(t) }
      end

      def add(tile)
        tile = Tiles::Tile.new(tile) unless tile.is_a?(Tiles::Tile)
        self.class.new(@tiles + [tile])
      end

      def remove(tile)
        tile = Tiles::Tile.new(tile) unless tile.is_a?(Tiles::Tile)
        idx = @tiles.index { |t| t == tile } || @tiles.index { |t| t.same_kind?(tile) }
        raise Errors::TileNotFoundError, "Tile #{tile} not found in hand" unless idx

        self.class.new(@tiles.dup.tap { |a| a.delete_at(idx) })
      end

      def remove_tiles(tiles_to_remove)
        result = self
        tiles_to_remove.each { |t| result = result.remove(t) }
        result
      end

      def count
        @tiles.size
      end

      def include?(tile)
        tile = Tiles::Tile.new(tile) unless tile.is_a?(Tiles::Tile)
        @tiles.any? { |t| t.same_kind?(tile) }
      end

      def count_of(tile)
        tile = Tiles::Tile.new(tile) unless tile.is_a?(Tiles::Tile)
        @tiles.count { |t| t.same_kind?(tile) }
      end

      def sorted
        self.class.new(@tiles.sort)
      end

      def to_34
        Tiles::TileSet.to_34(@tiles)
      end

      def to_a
        @tiles.map(&:to_s)
      end

      def self.from_array(arr)
        new(arr.map { |s| Tiles::Tile.new(s) })
      end

      def to_s
        sorted.tiles.map(&:to_s).join(" ")
      end
    end
  end
end
