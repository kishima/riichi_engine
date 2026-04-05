module Mahjong::Scoring::Yaku::Honitsu
      def self.check(ctx)
        all = ctx.all_tiles
        suits = all.select(&:suuhai?).map(&:suit).uniq
        return nil unless suits.size == 1
        return nil unless all.any?(&:jihai?)

        han = ctx.is_menzen ? 3 : 2
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "honitsu", han: han, display: "混一色")
      end
end
