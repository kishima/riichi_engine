module Mahjong::Scoring::Yaku::Chiitoitsu
      def self.check(ctx)
        return nil unless ctx.agari_form&.chiitoitsu?
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "chiitoitsu", han: 2, display: "七対子")
      end
end
