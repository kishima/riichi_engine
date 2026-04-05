module Mahjong::Scoring::Yaku::Chinroutou
      def self.check(ctx)
        return nil unless ctx.all_tiles.all?(&:routou?)
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "chinroutou", han: -1, display: "清老頭")
      end
end
