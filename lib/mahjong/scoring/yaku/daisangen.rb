module Mahjong::Scoring::Yaku::Daisangen
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?
        count = ctx.all_mentsu.count { |m| (m.koutsu? || m.kantsu?) && m.representative_tile.sangenpai? }
        return nil unless count == 3
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "daisangen", han: -1, display: "大三元")
      end
end
