module Mahjong
  module Scoring
    module ValueObjects
      class YakuJudgeResult
      attr_reader :yaku, :is_yakuman, :total_han

      def initialize(yaku:, is_yakuman:, total_han:)
        @yaku = yaku
        @is_yakuman = is_yakuman
        @total_han = total_han
      end

      def yakuman?
        is_yakuman
      end

      def has_yaku?
        yaku.any?
      end

      def to_a
        yaku.map { |y| { name: y.name, han: y.han } }
      end
      end
    end
  end
end
