module Mahjong::Scoring::Yaku::Shousuushii
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?

        mentsu = ctx.all_mentsu
        jantou = ctx.jantou_tile

        kaze_koutsu = mentsu.count { |m| (m.koutsu? || m.kantsu?) && m.representative_tile.kazehai? }
        kaze_jantou = jantou&.kazehai? ? 1 : 0

        return nil unless kaze_koutsu == 3 && kaze_jantou == 1
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "shousuushii", han: -1, display: "小四喜")
      end
end
