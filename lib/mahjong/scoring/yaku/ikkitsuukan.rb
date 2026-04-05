module Mahjong::Scoring::Yaku::Ikkitsuukan
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?

        numbers = ctx.all_mentsu.select(&:shuntsu?).map do |m|
          [m.representative_tile.suit, m.representative_tile.effective_number]
        end

        found = %w[m p s].any? { |s| [1, 4, 7].all? { |n| numbers.include?([s, n]) } }
        return nil unless found

        han = ctx.is_menzen ? 2 : 1
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "ikkitsuukan", han: han, display: "一気通貫")
      end
end
