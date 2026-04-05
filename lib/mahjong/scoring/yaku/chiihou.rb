module Mahjong::Scoring::Yaku::Chiihou
      def self.check(ctx)
        return nil unless ctx.is_first_turn && ctx.agari_type == :tsumo
        return nil if ctx.jikaze == "ton"
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "chiihou", han: -1, display: "地和")
      end
end
