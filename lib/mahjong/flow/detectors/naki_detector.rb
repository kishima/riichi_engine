module Mahjong
  module Flow
    module Detectors
      class NakiDetector
      def self.detect(state:, dahai_seat:, rule:, dahai_tile: nil)
        target_tile = dahai_tile || state.last_dahai&.dig(:tile)
        return {} unless target_tile

        target_tile = Tiles::Tile.new(target_tile) unless target_tile.is_a?(Tiles::Tile)
        options = {}

        4.times do |seat|
          next if seat == dahai_seat

          seat_options = []
          hand = state.hands[seat]
          next unless hand

          test_hand_34 = hand.to_34
          test_hand_34[Tiles::TileSet.tile_index(target_tile)] += 1

          if Rounds::RoundFlow.can_ron_agari?(state, seat, target_tile, rule)
            furiten = Scoring::Judges::FuritenJudge.judge(state: state, seat: seat)
            seat_options << { type: :ron_agari } unless furiten.furiten?
          end

          if state.wall && state.wall.remaining <= 0
            options[seat] = seat_options if seat_options.any?
            next
          end

          if state.riichi_flags[seat]
            options[seat] = seat_options if seat_options.any?
            next
          end

          seat_options << { type: :daiminkan } if kan_available?(state) && hand.count_of(target_tile) >= 3
          if hand.count_of(target_tile) >= 2
            pon_tiles = find_pon_tiles(hand, target_tile)
            seat_options << { type: :pon, tiles: pon_tiles } if discard_left?(hand, pon_tiles, target_tile, false, rule)
          end

          if (dahai_seat + 1) % 4 == seat && target_tile.suuhai?
            find_chi_sets(hand, target_tile).each do |tiles|
              seat_options << { type: :chi, tiles: tiles } if discard_left?(hand, tiles, target_tile, true, rule)
            end
          end

          options[seat] = seat_options unless seat_options.empty?
        end

        options
      end

      # 喰い替えを禁じるルール（kuikae が偽）では、鳴いた後に切れる牌が 1 枚も残らない鳴きは出さない。
      def self.discard_left?(hand, tiles, target, chi, rule)
        return true if rule.nil? || rule.kuikae?

        rest = tiles.reduce(hand) { |h, t| h.remove(Tiles::Tile.new(t)) }
        called = tiles.map { |t| Tiles::Tile.new(t) } + [target]
        forbidden = Rounds::RoundFlow.kuikae_kinds(target, called, chi)
        rest.tiles.any? { |t| forbidden.none? { |f| f.same_kind?(t) } }
      end

      def self.kan_available?(state)
        return true unless state.wanpai

        state.wanpai&.rinshan_remaining.to_i.positive? && state.wanpai&.dora_revealable?
      end

      def self.find_pon_tiles(hand, target)
        hand.tiles.select { |tile| tile.same_kind?(target) }.first(2).map(&:to_s)
      end

      def self.find_chi_sets(hand, target)
        return [] unless target.suuhai?

        suit = target.suit
        num = target.effective_number
        found = []

        [[num + 1, num + 2], [num - 1, num + 1], [num - 2, num - 1]].each do |a, b|
          next unless (1..9).cover?(a) && (1..9).cover?(b)

          t1 = hand.tiles.find { |tile| tile.suit == suit && tile.effective_number == a }
          t2 = hand.tiles.find { |tile| tile.suit == suit && tile.effective_number == b }
          found << [t1.to_s, t2.to_s] if t1 && t2
        end

        found.uniq
      end
      end
    end
  end
end
