module Mahjong::Scoring::Yaku::Yakuhai
      def self.check(ctx)
        return nil unless ctx.agari_form&.regular?

        results = []
        ctx.all_mentsu.select { |m| m.koutsu? || m.kantsu? }.each do |m|
          tile = m.representative_tile
          next unless tile.jihai?

          if tile.sangenpai?
            name    = { 5 => "yakuhai_haku", 6 => "yakuhai_hatsu", 7 => "yakuhai_chun" }[tile.number]
            display = { 5 => "役牌 白",       6 => "役牌 發",        7 => "役牌 中" }[tile.number]
            results << ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: name, han: 1, display: display)
          end

          if ctx.jikaze_yakuhai?(tile)
            results << ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "yakuhai_jikaze", han: 1, display: "自風 #{tile.japanese_name}")
          end

          if ctx.bakaze_yakuhai?(tile)
            results << ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "yakuhai_bakaze", han: 1, display: "場風 #{tile.japanese_name}")
          end
        end

        results.empty? ? nil : results
      end
end
