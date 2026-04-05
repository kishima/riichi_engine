module Mahjong::Scoring::Yaku::MenzenTsumo
      def self.check(ctx)
        return nil unless ctx.is_menzen && ctx.agari_type == :tsumo
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "menzen_tsumo", han: 1, display: "門前清自摸和")
      end
end
