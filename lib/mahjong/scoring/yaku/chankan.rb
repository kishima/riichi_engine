module Mahjong::Scoring::Yaku::Chankan
      def self.check(ctx)
        return nil unless ctx.is_chankan
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "chankan", han: 1, display: "槍槓")
      end
end
