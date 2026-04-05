module Mahjong::Scoring::Yaku::Tsuuiisou
      def self.check(ctx)
        return nil unless ctx.all_tiles.all?(&:jihai?)
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "tsuuiisou", han: -1, display: "字一色")
      end
end
