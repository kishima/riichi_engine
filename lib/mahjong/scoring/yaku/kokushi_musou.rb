module Mahjong::Scoring::Yaku::KokushiMusou
      def self.check(ctx)
        return nil unless ctx.agari_form&.kokushi?
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "kokushi_musou", han: -1, display: "国士無双")
      end
end
