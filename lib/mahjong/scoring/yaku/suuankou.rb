module Mahjong::Scoring::Yaku::Suuankou
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?
        return nil unless ctx.is_menzen

        ankou_count = ctx.all_mentsu.count { |m| (m.koutsu? || m.kantsu?) && m.closed? }

        if ctx.agari_type == :ron && ctx.machi_type == :shanpon
          ankou_count -= 1
        end

        return nil unless ankou_count >= 4

        # 単騎待ち（四暗刻単騎）は double_yakuman ならダブル役満
        if ctx.machi_type == :tanki && ctx.rule&.double_yakuman?
          return ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "suuankou", han: -2, display: "四暗刻単騎")
        end

        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "suuankou", han: -1, display: "四暗刻")
      end
end
