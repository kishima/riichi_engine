module Mahjong
  module Scoring
    module ValueObjects
      class YakuContext
      attr_reader :agari_form, :agari_tile, :agari_type, :hand_tiles, :fuuros, :is_menzen,
                  :jikaze, :bakaze, :is_riichi, :is_double_riichi, :is_ippatsu, :is_first_turn,
                  :is_haitei, :is_houtei, :is_rinshan, :is_chankan, :dora_tiles, :uradora_tiles,
                  :machi_type, :rule

      def initialize(**attrs)
        attrs.each { |k, v| instance_variable_set(:"@#{k}", v) }
      end

      def with_agari_form(form)
        self.class.new(
          agari_form: form,
          agari_tile: agari_tile,
          agari_type: agari_type,
          hand_tiles: hand_tiles,
          fuuros: fuuros,
          is_menzen: is_menzen,
          jikaze: jikaze,
          bakaze: bakaze,
          is_riichi: is_riichi,
          is_double_riichi: is_double_riichi,
          is_ippatsu: is_ippatsu,
          is_first_turn: is_first_turn,
          is_haitei: is_haitei,
          is_houtei: is_houtei,
          is_rinshan: is_rinshan,
          is_chankan: is_chankan,
          dora_tiles: dora_tiles,
          uradora_tiles: uradora_tiles,
          machi_type: machi_type,
          rule: rule
        )
      end

      def all_tiles
        hand_tiles + fuuros.flat_map(&:tiles)
      end

      def all_mentsu
        return [] unless agari_form&.regular?

        parsed_mentsu = agari_form.parsed_hand.mentsu_notations.map do |m|
          tiles = m[:tiles].map { |n| Tiles::Tile.new(n) }
          State::Mentsu.new(type: m[:type], tiles: tiles, state: :closed)
        end

        parsed_mentsu + fuuros.map(&:to_mentsu)
      end

      def jantou_tile
        return nil unless agari_form&.regular?

        Tiles::Tile.new(Tiles::TileSet.from_index(agari_form.parsed_hand.jantou_index))
      end

      def jikaze_yakuhai?(tile)
        tile.kazehai? && Tiles::Tile::KAZE_NAMES[tile.number] == jikaze
      end

      def bakaze_yakuhai?(tile)
        tile.kazehai? && Tiles::Tile::KAZE_NAMES[tile.number] == bakaze
      end
      end
    end
  end
end
