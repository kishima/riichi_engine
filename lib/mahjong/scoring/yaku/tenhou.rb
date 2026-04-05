module Mahjong::Scoring::Yaku::Tenhou
      def self.check(ctx)
        return nil unless ctx.is_first_turn && ctx.agari_type == :tsumo
        return nil unless ctx.jikaze == "ton"
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "tenhou", han: -1, display: "天和")
      end
end
