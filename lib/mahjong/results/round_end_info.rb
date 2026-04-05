module Mahjong
  module Results
    class RoundEndInfo
      attr_reader :result_type, :winners, :losers, :tenpai_seats, :draw_reason, :score_changes, :honba, :kyoutaku

      def initialize(**attrs)
        @result_type = attrs[:result_type]
        @winners = attrs[:winners] || []
        @losers = attrs[:losers] || []
        @tenpai_seats = attrs[:tenpai_seats] || []
        @draw_reason = attrs[:draw_reason]
        @score_changes = attrs[:score_changes] || {}
        @honba = attrs[:honba]
        @kyoutaku = attrs[:kyoutaku]
      end
    end
  end
end
