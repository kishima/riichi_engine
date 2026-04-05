module Mahjong::Scoring::Yaku::Toitoihou
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?
        return nil unless ctx.all_mentsu.all? { |m| m.koutsu? || m.kantsu? }
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "toitoihou", han: 2, display: "対々和")
      end
end
