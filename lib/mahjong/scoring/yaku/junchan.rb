module Mahjong::Scoring::Yaku::Junchan
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?

        mentsu = ctx.all_mentsu
        jantou = ctx.jantou_tile

        return nil unless mentsu.all?(&:includes_yaochu?) && jantou.routou?
        return nil unless mentsu.any?(&:shuntsu?)
        return nil if ctx.all_tiles.any?(&:jihai?)

        han = ctx.is_menzen ? 3 : 2
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "junchan", han: han, display: "純全帯么九")
      end
end
