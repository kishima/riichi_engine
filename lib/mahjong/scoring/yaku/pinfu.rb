module Mahjong::Scoring::Yaku::Pinfu
      def self.check(ctx)
        return nil unless ctx.is_menzen
        return nil unless ctx.agari_form&.regular?
        return nil unless ctx.machi_type == :ryanmen

        return nil unless ctx.all_mentsu.all?(&:shuntsu?)

        jt = ctx.jantou_tile
        return nil if jt.sangenpai?
        return nil if ctx.jikaze_yakuhai?(jt)
        return nil if ctx.bakaze_yakuhai?(jt)

        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "pinfu", han: 1, display: "平和")
      end
end
