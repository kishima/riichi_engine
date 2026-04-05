module Mahjong::Scoring::Yaku::Haitei
      def self.check(ctx)
        return nil unless ctx.is_haitei && ctx.agari_type == :tsumo
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "haitei", han: 1, display: "海底摸月")
      end
end
