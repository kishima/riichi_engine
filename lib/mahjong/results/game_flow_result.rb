module Mahjong
  module Results
    class GameFlowResult
      attr_reader :action, :reason, :next_bakaze, :next_kyoku,
                  :next_honba, :next_oya_index, :renchan

      def initialize(**attrs)
        attrs.each { |k, v| instance_variable_set(:"@#{k}", v) }
      end

      def game_end?
        action == :game_end
      end

      def next_round?
        action == :next_round
      end
    end
  end
end
