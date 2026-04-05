module Mahjong
  module State
    class Kawa
      KawaTile = Data.define(:tile, :tsumogiri, :riichi, :called)

      attr_reader :tiles

      def initialize
        @tiles = []
      end

      def add(tile, tsumogiri: false, riichi: false)
        @tiles << KawaTile.new(
          tile: tile.is_a?(Tiles::Tile) ? tile : Tiles::Tile.new(tile),
          tsumogiri: tsumogiri,
          riichi: riichi,
          called: false
        )
      end

      def mark_last_called!
        return if @tiles.empty?

        last = @tiles.pop
        @tiles << KawaTile.new(tile: last.tile, tsumogiri: last.tsumogiri,
                               riichi: last.riichi, called: true)
      end

      def discarded_tile_kinds
        @tiles.map { |kt| [kt.tile.suit, kt.tile.effective_number] }.uniq
      end

      def includes_kind?(tile)
        @tiles.any? { |kt| kt.tile.same_kind?(tile) }
      end

      def count
        @tiles.size
      end

      def last_tile
        @tiles.last&.tile
      end

      def to_a
        @tiles.map do |kt|
          {
            tile: kt.tile.to_s,
            tsumogiri: kt.tsumogiri,
            riichi: kt.riichi,
            called: kt.called
          }
        end
      end

      def self.from_array(arr)
        kawa = new
        arr.each do |h|
          kawa.add(h["tile"] || h[:tile],
                   tsumogiri: h["tsumogiri"] || h[:tsumogiri] || false,
                   riichi: h["riichi"] || h[:riichi] || false)
          kawa.mark_last_called! if h["called"] || h[:called]
        end
        kawa
      end
    end
  end
end
