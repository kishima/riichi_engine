module Mahjong
  module Tiles
    class Dora
      def self.count(all_tiles, dora_tiles)
        dora_tiles.sum do |dora|
          all_tiles.count { |t| t.same_kind?(dora) }
        end
      end

      def self.aka_count(all_tiles)
        all_tiles.count(&:aka?)
      end

      def self.uradora_count(all_tiles, uradora_tiles)
        count(all_tiles, uradora_tiles)
      end
    end
  end
end
