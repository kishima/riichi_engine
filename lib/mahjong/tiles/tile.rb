module Mahjong
  module Tiles
    class Tile
      SUITS = %w[m p s z].freeze
      MANZU  = "m"
      PINZU  = "p"
      SOUZU  = "s"
      JIHAI  = "z"

      # z の番号対応: 1=東, 2=南, 3=西, 4=北, 5=白, 6=發, 7=中
      KAZE_NAMES = { 1 => "ton", 2 => "nan", 3 => "sha", 4 => "pei" }.freeze
      SANGEN_NAMES = { 5 => "haku", 6 => "hatsu", 7 => "chun" }.freeze

      attr_reader :suit, :number, :is_aka

      # @param notation [String] "1m", "5p", "0s"(赤5), "1z"(東) 等
      def initialize(notation)
        @original = notation.to_s.freeze
        parse!(notation)
        freeze
      end

      def suuhai?
        suit != JIHAI
      end

      def jihai?
        suit == JIHAI
      end

      def kazehai?
        jihai? && number <= 4
      end

      def sangenpai?
        jihai? && number >= 5
      end

      def yaochu?
        jihai? || number == 1 || number == 9
      end

      def chunchan?
        suuhai? && number >= 2 && number <= 8
      end

      def routou?
        suuhai? && (number == 1 || number == 9)
      end

      def green?
        (suit == SOUZU && [2, 3, 4, 6, 8].include?(number)) ||
          (suit == JIHAI && number == 6)
      end

      def aka?
        is_aka
      end

      def effective_number
        aka? ? 5 : number
      end

      def same_kind?(other)
        suit == other.suit && effective_number == other.effective_number
      end

      def ==(other)
        return false unless other.is_a?(Tile)

        suit == other.suit && number == other.number && is_aka == other.is_aka
      end
      alias eql? ==

      def hash
        [suit, number, is_aka].hash
      end

      def <=>(other)
        return nil unless other.is_a?(Tile)

        [suit_order, effective_number] <=> [other.suit_order, other.effective_number]
      end
      include Comparable

      def to_s
        aka? ? "0#{suit}" : "#{number}#{suit}"
      end

      def inspect
        "#<Tile:#{to_s}>"
      end

      def japanese_name
        case suit
        when MANZU then "#{effective_number}萬"
        when PINZU then "#{effective_number}筒"
        when SOUZU then "#{effective_number}索"
        when JIHAI
          %w[_ 東 南 西 北 白 發 中][number]
        end
      end

      def next_tile_notation
        case suit
        when MANZU, PINZU, SOUZU
          next_num = (effective_number % 9) + 1
          "#{next_num}#{suit}"
        when JIHAI
          if kazehai?
            kaze_order = [1, 2, 3, 4]
            next_idx = (kaze_order.index(number) + 1) % 4
            "#{kaze_order[next_idx]}#{suit}"
          else
            sangen_order = [5, 6, 7]
            next_idx = (sangen_order.index(number) + 1) % 3
            "#{sangen_order[next_idx]}#{suit}"
          end
        end
      end

      def suit_order
        { MANZU => 0, PINZU => 1, SOUZU => 2, JIHAI => 3 }[suit]
      end

      def self.from(notation)
        new(notation)
      end

      def self.all_tiles(aka_config = { "m" => 1, "p" => 1, "s" => 1 })
        tiles = []
        %w[m p s].each do |s|
          (1..9).each do |n|
            aka_count = (n == 5) ? (aka_config[s] || 0) : 0
            normal_count = 4 - aka_count
            normal_count.times { tiles << new("#{n}#{s}") }
            aka_count.times { tiles << new("0#{s}") }
          end
        end
        (1..7).each do |n|
          4.times { tiles << new("#{n}z") }
        end
        tiles
      end

      private

      def parse!(notation)
        str = notation.to_s.strip
        raise ArgumentError, "Invalid tile notation: #{notation}" unless str.match?(/\A[0-9][mpsz]\z/)

        @number = str[0].to_i
        @suit = str[1]
        @is_aka = (@number == 0)

        validate_range!
      end

      def validate_range!
        if suit == JIHAI
          raise ArgumentError, "Invalid jihai number: #{number}" unless (1..7).include?(number)
        else
          raise ArgumentError, "Invalid suuhai number: #{number}" unless (0..9).include?(number)
        end
      end
    end
  end
end
