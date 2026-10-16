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

      def think_dahai(state, seat, available, rule)
        agari = available.find { |action| action[:type] == :tsumo_agari }
        return agari if agari

        if state.riichi_flags[seat]
          dahai = available.find { |action| action[:type] == :dahai }
          return dahai if dahai
        end

        riichi = available.find { |action| action[:type] == :riichi }
        if riichi
          tile = Judges::RiichiJudge.riichi_tile(state: state, seat: seat, choices: riichi[:choices]) ||
                 riichi[:choices]&.first || state.last_tsumo.to_s
          return { type: :riichi, tile: tile } if Judges::RiichiJudge.should_riichi?(state: state, seat: seat, level: level, tile: tile)
        end

        ankan = available.find { |action| action[:type] == :ankan }
        return ankan if ankan && should_ankan?(state, seat, ankan, rule)

        allowed = available.select { |action| action[:type] == :dahai }.map { |action| action[:tile].to_s }
        { type: :dahai, tile: Selectors::DahaiSelector.select(hand: state.hands[seat], state: state, level: level, seat: seat, allowed: allowed, rule: rule) }
      end

      def think_naki(state, seat, available, rule)
        Judges::NakiJudge.judge(naki_options: available, state: state, seat: seat, level: level, rule: rule) || { type: :skip }
      end

      # 鳴いた手の暗槓は、槓の後も役の筋（Analysis::YakuPlan）が残るときだけ（么九牌の暗槓で断么九が消える、など）。
      def should_ankan?(state, seat, ankan = nil, rule = nil)
        return true if ankan.nil? || Analysis::YakuPlan.menzen?(state, seat)

        tile = Tiles::Tile.new(ankan[:tile])
        kan = State::Fuuro.new(type: :ankan, tiles: Array.new(4) { tile })
        plans = Analysis::YakuPlan.seat_plans(state, seat, rule, fuuros: Array(state.fuuros[seat]) + [kan])
        !plans.empty?
      end
      end
    end
  end
end
