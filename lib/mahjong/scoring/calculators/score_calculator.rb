module Mahjong
  module Scoring
    module Calculators
      class ScoreCalculator
        def self.calculate(fu:, han:, is_oya:, agari_type:, honba: 0, kyoutaku: 0, is_yakuman: false, rule: nil)
          base = base_points(fu, han, is_yakuman, rule)
          payments = compute_payments(base, is_oya, agari_type, honba)

          ValueObjects::ScoreResult.new(
            fu: fu,
            han: han,
            base_points: base,
            level: score_level(base, han, is_yakuman),
            is_oya: is_oya,
            agari_type: agari_type,
            payments: payments,
            total: payments[:total],
            kyoutaku_bonus: kyoutaku * 1000,
            honba: honba,
            is_yakuman: is_yakuman
          )
        end

        def self.base_points(fu, han, is_yakuman, rule)
          return 8000 if is_yakuman
          return rule&.kazoe_yakuman? == false ? 6000 : 8000 if han >= 13
          return 6000 if han >= 11
          return 4000 if han >= 8
          return 3000 if han >= 6
          return 2000 if han >= 5

          base = fu * (2**(2 + han))
          return 2000 if rule&.kiriage_mangan? && ((fu == 30 && han == 4) || (fu == 60 && han == 3))

          [base, 2000].min
        end

        def self.compute_payments(base, is_oya, agari_type, honba)
          if agari_type == :tsumo
            if is_oya
              ko_pay = ceil100(base * 2) + honba * 100
              { ko_pays: ko_pay, total: ko_pay * 3 }
            else
              ko_pay = ceil100(base) + honba * 100
              oya_pay = ceil100(base * 2) + honba * 100
              { ko_pays: ko_pay, oya_pays: oya_pay, total: ko_pay * 2 + oya_pay }
            end
          else
            ron_pay = ceil100(base * (is_oya ? 6 : 4)) + honba * 300
            { ron_pay: ron_pay, total: ron_pay }
          end
        end

        def self.score_level(base, han, is_yakuman)
          return "役満" if is_yakuman
          return "数え役満" if han >= 13 && base == 8000

          case base
          when 6000 then "三倍満"
          when 4000 then "倍満"
          when 3000 then "跳満"
          when 2000 then "満貫"
          else ""
          end
        end

        def self.ceil100(value)
          ((value + 99) / 100) * 100
        end
      end
    end
  end
end
