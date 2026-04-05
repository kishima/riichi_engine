module Mahjong::Scoring::Yaku::Ippatsu
      def self.check(ctx)
        return nil unless ctx.is_ippatsu
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "ippatsu", han: 1, display: "一発")
      end
end
