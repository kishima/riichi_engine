module Mahjong::Scoring::Yaku::Suukantsu
      def self.check(ctx)
        return nil unless ctx.all_mentsu.count(&:kantsu?) == 4
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "suukantsu", han: -1, display: "四槓子")
      end
end
