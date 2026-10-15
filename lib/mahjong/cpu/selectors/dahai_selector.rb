module Mahjong
  module Cpu
    module Selectors
      class DahaiSelector
      # allowed: 切ってよい牌（喰い替えの禁止などで絞られたとき）。nil か空ならすべて。
      def self.select(hand:, state:, level:, allowed: nil)
        visible = collect_visible_tiles(state)
        evals = Analysis::TileEvaluator.evaluate_all_discards(hand, visible_tiles: visible)
        if allowed && !allowed.empty?
          kept = evals.select { |tile, _| allowed.include?(tile) }
          evals = kept unless kept.empty?
        end

        case level
        when 1 then select_easy(evals, hand)
        when 2 then select_normal(evals, hand, state)
        when 3 then select_hard(evals, hand, state)
        else select_normal(evals, hand, state)
        end
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
            result.ukeire,
            danger_score(Tiles::Tile.new(tile_str), state),
            tile_str
          ]
        end

        sorted.first&.first || hand.tiles.last.to_s
      end

      private_class_method def self.select_hard(evals, hand, state)
        min_shanten = evals.values.map(&:shanten).min
        return select_normal(evals, hand, state) if min_shanten <= 1

        riichi_seats = (0..3).select { |seat| state.riichi_flags[seat] && seat != state.current_seat }
        return select_defensive(evals, hand, state, riichi_seats) if riichi_seats.any?

        select_normal(evals, hand, state)
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
