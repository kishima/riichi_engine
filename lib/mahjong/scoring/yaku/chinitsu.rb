module Mahjong::Scoring::Yaku::Chinitsu
      def self.check(ctx)
        all = ctx.all_tiles
        return nil if all.any?(&:jihai?)
        return nil unless all.map(&:suit).uniq.size == 1

        han = ctx.is_menzen ? 6 : 5
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "chinitsu", han: han, display: "清一色")
      end
end
