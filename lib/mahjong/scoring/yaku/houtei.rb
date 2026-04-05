module Mahjong::Scoring::Yaku::Houtei
      def self.check(ctx)
        return nil unless ctx.is_houtei && ctx.agari_type == :ron
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "houtei", han: 1, display: "河底撈魚")
      end
end
