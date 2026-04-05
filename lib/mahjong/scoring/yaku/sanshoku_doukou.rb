module Mahjong::Scoring::Yaku::SanshokuDoukou
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?

        numbers = ctx.all_mentsu.select { |m| m.koutsu? || m.kantsu? }.map do |m|
          [m.representative_tile.suit, m.representative_tile.effective_number]
        end

        found = (1..9).any? { |n| %w[m p s].all? { |s| numbers.include?([s, n]) } }
        return nil unless found

        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "sanshoku_doukou", han: 2, display: "三色同刻")
      end
end
