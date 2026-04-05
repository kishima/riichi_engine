module Mahjong::Scoring::Yaku::Tanyao
      def self.check(ctx)
        return nil if !ctx.is_menzen && !ctx.rule.kuitan?
        return nil unless ctx.all_tiles.all?(&:chunchan?)
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "tanyao", han: 1, display: "断么九")
      end
end
