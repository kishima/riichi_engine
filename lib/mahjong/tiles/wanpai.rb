module Mahjong
  module Tiles
    class Wanpai
      TOTAL = 14
      MAX_RINSHAN = 4
      MAX_DORA_HYOUJI = 5

      attr_reader :rinshan_tiles, :dora_hyouji, :uradora_hyouji

      def initialize(tiles)
        raise Errors::EngineError, "Wanpai must have #{TOTAL} tiles" unless tiles.size == TOTAL

        @rinshan_tiles = tiles[0..3].dup
        @dora_hyouji = [tiles[4]]
        @uradora_hyouji = [tiles[9]]
        @remaining_dora = tiles[5..8].dup
        @remaining_uradora = tiles[10..13].dup
      end

      def draw_rinshan!
        raise Errors::EngineError, "No rinshan tiles left" if @rinshan_tiles.empty?

        @rinshan_tiles.shift
      end

      def reveal_new_dora!
        raise Errors::EngineError, "No more dora to reveal" if @remaining_dora.empty?

        new_dora = @remaining_dora.shift
        new_uradora = @remaining_uradora.shift
        @dora_hyouji << new_dora
        @uradora_hyouji << new_uradora if new_uradora
        new_dora
      end

      def dora_tiles
        @dora_hyouji.map { |t| Tiles::Tile.new(t.next_tile_notation) }
      end

      def uradora_tiles
        @uradora_hyouji.map { |t| Tiles::Tile.new(t.next_tile_notation) }
      end

      def rinshan_remaining
        @rinshan_tiles.size
      end

      def dora_revealable?
        @remaining_dora.any? && @remaining_uradora.any?
      end

      def to_h
        {
          rinshan: @rinshan_tiles.map(&:to_s),
          dora_hyouji: @dora_hyouji.map(&:to_s),
          uradora_hyouji: @uradora_hyouji.map(&:to_s),
          remaining_dora: @remaining_dora.map(&:to_s),
          remaining_uradora: @remaining_uradora.map(&:to_s)
        }
      end

      def self.from_hash(h)
        rinshan = (h["rinshan"] || h[:rinshan] || []).map { |s| Tiles::Tile.new(s) }
        dh = (h["dora_hyouji"] || h[:dora_hyouji] || []).map { |s| Tiles::Tile.new(s) }
        uh = (h["uradora_hyouji"] || h[:uradora_hyouji] || []).map { |s| Tiles::Tile.new(s) }
        remaining_dora = (h["remaining_dora"] || h[:remaining_dora] || []).map { |s| Tiles::Tile.new(s) }
        remaining_uradora = (h["remaining_uradora"] || h[:remaining_uradora] || []).map { |s| Tiles::Tile.new(s) }

        obj = allocate
        obj.instance_variable_set(:@rinshan_tiles, rinshan)
        obj.instance_variable_set(:@dora_hyouji, dh)
        obj.instance_variable_set(:@uradora_hyouji, uh)
        obj.instance_variable_set(:@remaining_dora, remaining_dora)
        obj.instance_variable_set(:@remaining_uradora, remaining_uradora)
        obj
      end
    end
  end
end
