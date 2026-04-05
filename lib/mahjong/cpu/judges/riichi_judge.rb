module Mahjong
  module Cpu
    module Judges
      class RiichiJudge
      def self.should_riichi?(state:, seat:, level:)
        return false unless state.menzen_flags[seat]
        return false if state.riichi_flags[seat]
        return false if state.scores[seat] < 1000
        return false if state.wall.remaining < 4
        return false unless Scoring::Judges::MachiJudge.tenpai?(state.hands[seat].to_34)

        case level
        when 1
          true
        when 2
          Scoring::Judges::MachiJudge.machi_tile_indices(state.hands[seat].to_34).size >= 2
        when 3
          should_riichi_hard?(state, seat)
        else
          true
        end
      end

      private_class_method def self.should_riichi_hard?(state, seat)
        machi_indices = Scoring::Judges::MachiJudge.machi_tile_indices(state.hands[seat].to_34)
        visible = Selectors::DahaiSelector.send(:collect_visible_tiles, state)
        remaining = Analysis::TileEvaluator.build_remaining_counts(visible)
        live_machi_count = machi_indices.sum { |i| remaining[i] }
        remaining_turns = state.wall.remaining / 4

        return true if live_machi_count >= 4 && remaining_turns >= 5

        other_riichi = (0..3).count { |other_seat| other_seat != seat && state.riichi_flags[other_seat] }
        return false if other_riichi >= 2
        return true if live_machi_count >= 6

        false
      end
      end
    end
  end
end
