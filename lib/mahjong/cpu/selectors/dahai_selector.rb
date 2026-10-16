module Mahjong
  module Cpu
    module Selectors
      class DahaiSelector
      # seat: 手の持ち主（省略すると手番の席）。その席の副露を面子として数える。
      # allowed: 切ってよい牌（喰い替えの禁止などで絞られたとき）。nil か空ならすべて。
      # rule: 喰い断の有無を見る（省略すると喰い断あり）。
      def self.select(hand:, state:, level:, seat: state.current_seat, allowed: nil, rule: nil)
        visible = collect_visible_tiles(state)
        melds = Array(state.fuuros && state.fuuros[seat]).size
        evals = Analysis::TileEvaluator.evaluate_all_discards(hand, visible_tiles: visible, melds: melds)
        if allowed && !allowed.empty?
          kept = evals.select { |tile, _| allowed.include?(tile) }
          evals = kept unless kept.empty?
        end

        case level
        when 1 then select_easy(evals, hand)
        when 3 then select_hard(evals, hand, state, on_yaku_plan(evals, hand, state, seat, melds, rule))
        else select_normal(on_yaku_plan(evals, hand, state, seat, melds, rule), hand, state)
        end
      end

      # 鳴いた手では、役の筋（Analysis::YakuPlan）に沿った向聴数がいちばん小さくなる打牌だけを残す。
      # そのうち通常の向聴数が筋の向聴数と同じ打牌があれば、それだけにする（通常の数え方でだけ進んで見える
      # 打牌、たとえば么九牌を雀頭にした断么九の無いテンパイを取らない）。門前の手と、筋の残っていない手はそのまま。
      private_class_method def self.on_yaku_plan(evals, hand, state, seat, melds, rule)
        plans = Analysis::YakuPlan.seat_plans(state, seat, rule)
        return evals if plans.nil? || plans.empty?

        planned = evals.to_h do |tile_str, result|
          [tile_str, Analysis::YakuPlan.best_shanten(plans, hand.remove(Tiles::Tile.new(tile_str)).to_34, melds)]
        end
        best = planned.values.min
        kept = evals.select { |tile_str, _| planned[tile_str] == best }
        on_plan = kept.select { |_, result| result.shanten == best }
        on_plan.empty? ? kept : on_plan
      end

      private_class_method def self.select_easy(evals, hand)
        min_shanten = evals.values.map(&:shanten).min
        candidates = evals.select { |_tile, result| result.shanten == min_shanten }

        sorted = candidates.sort_by do |tile_str, result|
          tile = Tiles::Tile.new(tile_str)
          [
            tile.yaochu? ? 0 : 1,
            result.ukeire,
            tile.to_s
          ]
        end

        sorted.first&.first || hand.tiles.last.to_s
      end

      private_class_method def self.select_normal(evals, hand, state)
        min_shanten = evals.values.map(&:shanten).min
        candidates = evals.select { |_tile, result| result.shanten == min_shanten }

        sorted = candidates.sort_by do |tile_str, result|
          [
            -result.ukeire,
            danger_score(Tiles::Tile.new(tile_str), state),
            tile_str
          ]
        end

        sorted.first&.first || hand.tiles.last.to_s
      end

      # planned: 役の筋に沿った打牌（on_yaku_plan）。守りに回るときは筋を見ない。
      private_class_method def self.select_hard(evals, hand, state, planned = evals)
        min_shanten = evals.values.map(&:shanten).min
        return select_normal(planned, hand, state) if min_shanten <= 1

        riichi_seats = (0..3).select { |seat| state.riichi_flags[seat] && seat != state.current_seat }
        return select_defensive(evals, hand, state, riichi_seats) if riichi_seats.any?

        select_normal(planned, hand, state)
      end

      private_class_method def self.select_defensive(evals, hand, state, riichi_seats)
        genbutsu = riichi_seats.flat_map do |seat|
          state.kawas[seat].tiles.map { |kawa_tile| kawa_tile.tile.to_s }
        end.uniq

        min_shanten = evals.values.map(&:shanten).min
        safe_candidates = evals.select do |tile_str, result|
          genbutsu.include?(tile_str) && result.shanten <= min_shanten + 1
        end

        if safe_candidates.any?
          return safe_candidates.min_by { |_tile, result| [result.shanten, -result.ukeire] }.first
        end

        select_normal(evals, hand, state)
      end

      private_class_method def self.danger_score(tile, _state)
        return 0 if tile.jihai?
        return 1 if tile.routou?
        return 3 if tile.effective_number.between?(4, 6)

        2
      end

      private_class_method def self.collect_visible_tiles(state)
        visible = []

        4.times do |seat|
          state.kawas[seat].tiles.each { |kawa_tile| visible << kawa_tile.tile }
          state.fuuros[seat].each { |fuuro| visible.concat(fuuro.tiles) }
        end
        state.dora_hyouji.each { |tile| visible << tile }

        visible
      end
      end
    end
  end
end
