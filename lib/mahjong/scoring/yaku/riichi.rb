module Mahjong::Scoring::Yaku::Riichi
      def self.check(ctx)
        return nil unless ctx.is_riichi && !ctx.is_double_riichi
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "riichi", han: 1, display: "立直")
      end
end
