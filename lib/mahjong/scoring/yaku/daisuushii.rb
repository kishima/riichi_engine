module Mahjong::Scoring::Yaku::Daisuushii
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?
        count = ctx.all_mentsu.count { |m| (m.koutsu? || m.kantsu?) && m.representative_tile.kazehai? }
        return nil unless count == 4
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "daisuushii", han: -1, display: "大四喜")
      end
end
