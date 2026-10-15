module Mahjong::Scoring::Yaku::KokushiMusou
      def self.check(ctx)
        return nil unless ctx.agari_form&.kokushi?

        # 和了牌の前に 13 種がそろっていた（十三面待ち）は double_yakuman ならダブル役満
        if ctx.rule&.double_yakuman? && thirteen_wait?(ctx)
          return ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "kokushi_musou", han: -2, display: "国士無双十三面")
        end

        ::Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "kokushi_musou", han: -1, display: "国士無双")
      end

      def self.thirteen_wait?(ctx)
        rest = ctx.hand_tiles.dup
        index = rest.index { |tile| tile.same_kind?(ctx.agari_tile) }
        return false unless index

        rest.delete_at(index)
        rest.map { |tile| [tile.suit, tile.effective_number] }.uniq.size == 13
      end
end
