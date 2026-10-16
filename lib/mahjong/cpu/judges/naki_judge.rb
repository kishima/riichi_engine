module Mahjong
  module Cpu
    module Judges
      class NakiJudge
      # rule: 喰い断の有無を見る（省略すると喰い断あり）。
      def self.judge(naki_options:, state:, seat:, level:, rule: nil)
        ron = naki_options.find { |option| option[:type] == :ron_agari }
        return ron if ron

        case level
        when 1 then judge_easy(naki_options)
        when 2 then judge_normal(naki_options, state, seat, rule)
        when 3 then judge_hard(naki_options, state, seat, rule)
        else judge_normal(naki_options, state, seat, rule)
        end
      end

      private_class_method def self.judge_easy(options)
        pon = options.find { |option| option[:type] == :pon }
        return nil unless pon

        tile = Tiles::Tile.new(pon[:tiles].first)
        tile.sangenpai? ? pon : nil
      end

      # 鳴いた後に役の筋（Analysis::YakuPlan）が残り、その筋に沿った向聴数が今より下がる鳴きだけを選ぶ。
      # 今の向聴数は、門前なら通常の向聴数、鳴いていればいちばん近い筋の向聴数。
      private_class_method def self.judge_normal(options, state, seat, rule)
        hand = state.hands[seat]
        fuuros = Array(state.fuuros && state.fuuros[seat])
        melds = fuuros.size
        plans = Analysis::YakuPlan.seat_plans(state, seat, rule)
        current_shanten = if plans
                            Analysis::YakuPlan.best_shanten(plans, hand.to_34, melds) || 8
                          else
                            Analysis::Shanten.calculate(hand.to_34, melds: melds)
                          end
        return nil if should_keep_menzen?(hand, current_shanten)

        options.each do |option|
          next unless %i[pon chi].include?(option[:type])

          choice_tiles(option).each do |tiles|
            from_hand = tiles.map { |t| Tiles::Tile.new(t) }
            called = state.last_dahai&.dig(:tile) || from_hand.first
            meld = State::Fuuro.new(type: option[:type], tiles: from_hand + [called])
            after_plans = Analysis::YakuPlan.seat_plans(state, seat, rule, fuuros: fuuros + [meld])
            next if after_plans.empty?

            after = Analysis::YakuPlan.best_shanten(after_plans, hand.remove_tiles(from_hand).to_34, melds + 1)
            return { type: option[:type], tiles: tiles } if after < current_shanten
          end
        end

        nil
      end

      private_class_method def self.judge_hard(options, state, seat, rule)
        judge_normal(options, state, seat, rule)
      end

      # 鳴きの候補の手牌の組（チーで組が複数あれば choices: のそれぞれ）
      private_class_method def self.choice_tiles(option)
        return option[:choices].map { |tiles| Array(tiles).map(&:to_s) } if option[:choices]

        [Array(option[:tiles]).map(&:to_s)]
      end

      private_class_method def self.should_keep_menzen?(_hand, shanten)
        shanten <= 1
      end
      end
    end
  end
end
