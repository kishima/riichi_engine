module Mahjong
  module Results
    class RoundFlowResult
      attr_reader :state, :events, :round_end, :round_end_info

      def initialize(state:, events: [], round_end: false, round_end_info: nil)
        @state = state
        @events = events
        @round_end = round_end
        @round_end_info = round_end_info
      end

      def round_end?
        @round_end
      end
    end
  end
end
