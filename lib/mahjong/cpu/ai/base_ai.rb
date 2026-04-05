module Mahjong
  module Cpu
    module Ai
      class BaseAi
      attr_reader :level

      def initialize(level:)
        @level = level
      end

      def think(state:, seat:, available:, rule:)
        return nil if available.empty?

        case state.phase
        when :dahai
          think_dahai(state, seat, available, rule)
        when :naki_wait
          think_naki(state, seat, available, rule)
        end
      end

      private

      def think_dahai(state, seat, available, _rule)
        agari = available.find { |action| action[:type] == :tsumo_agari }
        return agari if agari

        riichi = available.find { |action| action[:type] == :riichi }
        if riichi && Judges::RiichiJudge.should_riichi?(state: state, seat: seat, level: level)
          tile = riichi[:choices]&.first || state.last_tsumo.to_s
          return { type: :riichi, tile: tile }
        end

        ankan = available.find { |action| action[:type] == :ankan }
        return ankan if ankan && should_ankan?(state, seat)

        { type: :dahai, tile: Selectors::DahaiSelector.select(hand: state.hands[seat], state: state, level: level) }
      end

      def think_naki(state, seat, available, _rule)
        Judges::NakiJudge.judge(naki_options: available, state: state, seat: seat, level: level) || { type: :skip }
      end

      def should_ankan?(_state, _seat)
        true
      end
      end
    end
  end
end
