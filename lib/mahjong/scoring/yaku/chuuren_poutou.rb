module Mahjong::Scoring::Yaku::ChuurenPoutou
      def self.check(ctx)
        return nil unless ctx.is_menzen

        all = ctx.all_tiles
        return nil if all.any?(&:jihai?)

        suits = all.map(&:suit).uniq
        return nil unless suits.size == 1

        counts = Array.new(10, 0)
        all.each { |t| counts[t.effective_number] += 1 }

        # 1112345678999 + 任意1枚 の形
        base = [3, 1, 1, 1, 1, 1, 1, 1, 3]
        (1..9).each { |n| return nil if counts[n] < base[n - 1] }

        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "chuuren_poutou", han: -1, display: "九蓮宝燈")
      end
end
