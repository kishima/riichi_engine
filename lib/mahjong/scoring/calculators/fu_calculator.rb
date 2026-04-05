module Mahjong
  module Scoring
    module Calculators
      class FuCalculator
      def self.calculate(context)
        return 25 if context.agari_form&.chiitoitsu?
        return 30 if context.agari_form&.kokushi?

        fu = 20
        fu += 10 if context.is_menzen && context.agari_type == :ron

        if context.agari_type == :tsumo
          return 20 if pinfu?(context)

          fu += 2
        end

        fu += context.all_mentsu.sum(&:fu)
        fu += jantou_fu(context)
        fu += machi_fu(context.machi_type)
        fu = 30 if !context.is_menzen && fu == 20

        round_up_fu(fu)
      end

      def self.pinfu?(context)
        return false unless context.agari_form&.regular?
        return false unless context.is_menzen
        return false unless context.machi_type == :ryanmen
        return false unless context.all_mentsu.all?(&:shuntsu?)

        jantou = context.jantou_tile
        return false if jantou.sangenpai?
        return false if context.jikaze_yakuhai?(jantou)
        return false if context.bakaze_yakuhai?(jantou)

        true
      end

      def self.jantou_fu(context)
        jantou = context.jantou_tile
        return 0 unless jantou

        return context.rule.renpuu_jantou_fu if context.jikaze_yakuhai?(jantou) && context.bakaze_yakuhai?(jantou)

        fu = 0
        fu += 2 if jantou.sangenpai?
        fu += 2 if context.jikaze_yakuhai?(jantou)
        fu += 2 if context.bakaze_yakuhai?(jantou)
        fu
      end

      def self.machi_fu(machi_type)
        case machi_type
        when :penchan, :kanchan, :tanki then 2
        else 0
        end
      end

      def self.round_up_fu(fu)
        return 25 if fu == 25

        ((fu + 9) / 10) * 10
      end
      end
    end
  end
end
