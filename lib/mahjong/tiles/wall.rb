module Mahjong
  module Tiles
    class Wall
      attr_reader :tiles

      def initialize(tiles)
        @tiles = tiles.dup
      end

      def draw!
        raise Errors::EngineError, "Wall is empty" if @tiles.empty?

        @tiles.shift
      end

      def draw_many!(count)
        raise Errors::EngineError, "Not enough tiles in wall" if @tiles.size < count

        @tiles.shift(count)
      end

      def draw_from_end!
        raise Errors::EngineError, "Wall is empty" if @tiles.empty?

        @tiles.pop
      end

      def remaining
        @tiles.size
      end

      def empty?
        @tiles.empty?
      end

      def to_a
        @tiles.map(&:to_s)
      end

      def self.build(aka_config: { "m" => 1, "p" => 1, "s" => 1 }, seed: nil)
        all = Tile.all_tiles(aka_config)
        rng = seed ? Random.new(seed.to_i(36)) : Random.new
        new(all.shuffle(random: rng))
      end
    end
  end
end
