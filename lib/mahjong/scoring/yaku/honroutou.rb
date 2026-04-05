module Mahjong::Scoring::Yaku::Honroutou
      def self.check(ctx)
        all = ctx.all_tiles
        return nil unless all.all?(&:yaochu?)
        return nil unless all.any?(&:jihai?)
        return nil unless all.any?(&:routou?)
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "honroutou", han: 2, display: "混老頭")
      end
end
