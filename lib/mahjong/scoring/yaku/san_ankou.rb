module Mahjong::Scoring::Yaku::SanAnkou
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?

        ankou_count = ctx.all_mentsu.count { |m| (m.koutsu? || m.kantsu?) && m.closed? }

        # ロンかつ双碰の場合、和了牌で完成した刻子は明刻扱い
        if ctx.agari_type == :ron && ctx.machi_type == :shanpon
          ankou_count -= 1 if ankou_count > 0
        end

        return nil unless ankou_count >= 3
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "san_ankou", han: 2, display: "三暗刻")
      end
end
