module Mahjong::Scoring::Yaku::Ryuuiisou
      def self.check(ctx)
        return nil unless ctx.all_tiles.all?(&:green?)
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "ryuuiisou", han: -1, display: "緑一色")
      end
end
