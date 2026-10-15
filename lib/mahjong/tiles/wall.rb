require "digest"

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
        rng = seed ? Random.new(seed_number(seed)) : Random.new
        new(all.shuffle(random: rng))
      end

      # 英数字だけの seed は従来どおり 36 進数として読む。それ以外の文字を含む seed は
      # to_i(36) がそこで止まってしまうため、文字列全体のハッシュを使う。
      def self.seed_number(seed)
        str = seed.to_s
        return str.to_i(36) if str.match?(/\A[0-9a-z]+\z/i)

        Digest::SHA256.hexdigest(str).to_i(16)
      end
      private_class_method :seed_number
    end
  end
end
