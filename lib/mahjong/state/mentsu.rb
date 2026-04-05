module Mahjong
  module State
    class Mentsu
      TYPES = %i[shuntsu koutsu kantsu].freeze
      STATES = %i[open closed].freeze

      attr_reader :type, :tiles, :state

      def initialize(type:, tiles:, state: :closed)
        @type = type
        @tiles = tiles.freeze
        @state = state
        freeze
      end

      def shuntsu? = type == :shuntsu
      def koutsu? = type == :koutsu
      def kantsu? = type == :kantsu
      def open? = state == :open
      def closed? = state == :closed

      def representative_tile
        tiles.min
      end

      def includes_yaochu?
        tiles.any?(&:yaochu?)
      end

      def all_yaochu?
        tiles.all?(&:yaochu?)
      end

      def all_chunchan?
        tiles.all?(&:chunchan?)
      end

      def fu
        base = case type
               when :shuntsu then 0
               when :koutsu then open? ? 2 : 4
               when :kantsu then open? ? 8 : 16
               end
        yaochu_multiplier = representative_tile.yaochu? ? 2 : 1
        base * yaochu_multiplier
      end

      def to_s
        state_str = open? ? "明" : "暗"
        type_str = { shuntsu: "順", koutsu: "刻", kantsu: "槓" }[type]
        "[#{state_str}#{type_str}: #{tiles.map(&:to_s).join(',')}]"
      end
    end
  end
end
