module Mahjong::Scoring::Yaku::Shousangen
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?

        mentsu = ctx.all_mentsu
        jantou = ctx.jantou_tile

        sangen_koutsu = mentsu.count { |m| (m.koutsu? || m.kantsu?) && m.representative_tile.sangenpai? }
        sangen_jantou = jantou&.sangenpai? ? 1 : 0

        return nil unless sangen_koutsu == 2 && sangen_jantou == 1
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "shousangen", han: 2, display: "小三元")
      end
end
