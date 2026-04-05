module Mahjong::Scoring::Yaku::SanKantsu
      def self.check(ctx)
        return nil unless ctx.all_mentsu.count(&:kantsu?) >= 3
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "san_kantsu", han: 2, display: "三槓子")
      end
end
