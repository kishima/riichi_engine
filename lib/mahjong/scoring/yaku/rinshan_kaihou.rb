module Mahjong::Scoring::Yaku::RinshanKaihou
      def self.check(ctx)
        return nil unless ctx.is_rinshan
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "rinshan_kaihou", han: 1, display: "嶺上開花")
      end
end
