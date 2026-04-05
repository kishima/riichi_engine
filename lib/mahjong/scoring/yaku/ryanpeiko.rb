module Mahjong::Scoring::Yaku::Ryanpeiko
      def self.check(ctx)
        return nil unless ctx.is_menzen
        return nil unless ctx.agari_form&.regular?

        shuntsu = ctx.all_mentsu.select(&:shuntsu?)
        return nil unless ::Mahjong::Scoring::Yaku::Iipeiko.count_shuntsu_pairs(shuntsu) == 2

        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "ryanpeiko", han: 3, display: "二盃口")
      end
end
