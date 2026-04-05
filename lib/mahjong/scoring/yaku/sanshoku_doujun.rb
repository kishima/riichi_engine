module Mahjong::Scoring::Yaku::SanshokuDoujun
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?

        numbers = ctx.all_mentsu.select(&:shuntsu?).map do |m|
          [m.representative_tile.suit, m.representative_tile.effective_number]
        end

        found = (1..7).any? { |n| %w[m p s].all? { |s| numbers.include?([s, n]) } }
        return nil unless found

        han = ctx.is_menzen ? 2 : 1
        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "sanshoku_doujun", han: han, display: "三色同順")
      end
end
