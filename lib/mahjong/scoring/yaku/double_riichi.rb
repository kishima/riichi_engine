module Mahjong::Scoring::Yaku::DoubleRiichi
      def self.check(ctx)
        return nil unless ctx.is_double_riichi
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "double_riichi", han: 2, display: "ダブル立直")
      end
end
