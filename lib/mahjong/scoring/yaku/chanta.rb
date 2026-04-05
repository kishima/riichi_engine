module Mahjong::Scoring::Yaku::Chanta
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?

        mentsu = ctx.all_mentsu
        jantou = ctx.jantou_tile

        return nil unless mentsu.all?(&:includes_yaochu?) && jantou.yaochu?
        return nil unless mentsu.any?(&:shuntsu?)
        return nil unless ctx.all_tiles.any?(&:jihai?)

        han = ctx.is_menzen ? 2 : 1
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "chanta", han: han, display: "混全帯么九")
      end
end
