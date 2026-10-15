module Mahjong::Scoring::Yaku::Iipeiko
      def self.check(ctx)
        return nil unless ctx.is_menzen
        return nil unless ctx.agari_form&.regular?

        shuntsu = ctx.all_mentsu.select(&:shuntsu?)
        return nil unless count_shuntsu_pairs(shuntsu) == 1

        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "iipeiko", han: 1, display: "一盃口")
      end

      def self.count_shuntsu_pairs(shuntsu_list)
        keys = shuntsu_list.map { |m| t = m.representative_tile; [t.suit, t.effective_number] }
        keys.tally.values.sum { |c| c / 2 }
      end
end
