module Mahjong::Scoring::Yaku::ChuurenPoutou
      BASE = [3, 1, 1, 1, 1, 1, 1, 1, 3].freeze

      def self.check(ctx)
        return nil unless ctx.is_menzen

        all = ctx.all_tiles
        return nil if all.any?(&:jihai?)

        suits = all.map(&:suit).uniq
        return nil unless suits.size == 1

        counts = Array.new(10, 0)
        all.each { |t| counts[t.effective_number] += 1 }

        # 1112345678999 + 任意1枚 の形
        (1..9).each { |n| return nil if counts[n] < BASE[n - 1] }

        # 和了牌の前が 1112345678999（九面待ち）は double_yakuman ならダブル役満（純正九蓮宝燈）
        if ctx.rule&.double_yakuman? && ctx.agari_tile
          counts[ctx.agari_tile.effective_number] -= 1
          if (1..9).all? { |n| counts[n] == BASE[n - 1] }
            return ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "chuuren_poutou", han: -2, display: "純正九蓮宝燈")
          end
        end

        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "chuuren_poutou", han: -1, display: "九蓮宝燈")
      end
end
