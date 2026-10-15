module Mahjong
  module Cpu
    module Judges
      class RiichiJudge
      # tile: リーチで切る牌。手が打牌の前（14 枚）なら、その牌を切った後の手で判断する。
      # 省略すると、14 枚の手では riichi_tile が選ぶ牌を切った後の手で判断する
      # （13 枚の手はそのまま）。
      def self.should_riichi?(state:, seat:, level:, tile: nil)
        return false unless state.menzen_flags[seat]
        return false if state.riichi_flags[seat]
        return false if state.scores[seat] < 1000
        return false if state.wall.remaining < 4

        hand = hand_after_discard(state, seat, tile)
        return false unless hand

        tiles_34 = hand.to_34
        return false unless Scoring::Judges::MachiJudge.tenpai?(tiles_34)

        case level
        when 1
          true
        when 2
          Scoring::Judges::MachiJudge.machi_tile_indices(tiles_34).size >= 2
        when 3
          should_riichi_hard?(state, seat, tiles_34)
        else
          true
        end
      end

      # リーチで切る牌: 候補（choices、省略時はテンパイを保つ打牌すべて）のうち、
      # 待ちの残り枚数（自分の手と見えている牌を除く）がいちばん多いもの。
      def self.riichi_tile(state:, seat:, choices: nil)
        hand = state.hands[seat]
        choices ||= hand.tiles.map(&:to_s).uniq
        visible = Selectors::DahaiSelector.send(:collect_visible_tiles, state)
        remaining = Analysis::TileEvaluator.build_remaining_counts(visible + hand.tiles)

        scored = choices.filter_map do |choice|
          rest = hand.remove(choice).to_34
          waits = Scoring::Judges::MachiJudge.machi_tile_indices(rest)
          next if waits.empty?

          [choice, waits.sum { |i| [remaining[i], 0].max }]
        rescue Errors::TileNotFoundError
          nil
        end
        scored.max_by { |_choice, live| live }&.first
      end

      def self.hand_after_discard(state, seat, tile)
        hand = state.hands[seat]
        return hand if tile.nil? && (hand.count % 3) != 2

        tile ||= riichi_tile(state:, seat:)
        return nil unless tile

        hand.remove(tile)
      rescue Errors::TileNotFoundError
        nil
      end
      private_class_method :hand_after_discard

      private_class_method def self.should_riichi_hard?(state, seat, tiles_34)
        machi_indices = Scoring::Judges::MachiJudge.machi_tile_indices(tiles_34)
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
