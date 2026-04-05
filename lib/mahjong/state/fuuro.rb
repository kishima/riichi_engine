module Mahjong
  module State
    class Fuuro
      TYPES = %i[chi pon ankan daiminkan kakan].freeze

      attr_reader :type, :tiles, :called_tile, :from_seat

      def initialize(type:, tiles:, called_tile: nil, from_seat: nil)
        @type = type
        @tiles = tiles.freeze
        @called_tile = called_tile
        @from_seat = from_seat
        freeze
      end

      def chi? = type == :chi
      def pon? = type == :pon
      def ankan? = type == :ankan
      def daiminkan? = type == :daiminkan
      def kakan? = type == :kakan
      def kan? = ankan? || daiminkan? || kakan?

      def keeps_menzen?
        ankan?
      end

      def to_mentsu
        case type
        when :chi
          State::Mentsu.new(type: :shuntsu, tiles: tiles, state: :open)
        when :pon
          State::Mentsu.new(type: :koutsu, tiles: tiles, state: :open)
        when :ankan
          State::Mentsu.new(type: :kantsu, tiles: tiles, state: :closed)
        when :daiminkan, :kakan
          State::Mentsu.new(type: :kantsu, tiles: tiles, state: :open)
        end
      end

      def to_s
        "#{type}[#{tiles.map(&:to_s).join(',')}]"
      end
    end
  end
end
