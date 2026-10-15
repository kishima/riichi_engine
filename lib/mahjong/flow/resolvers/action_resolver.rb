module Mahjong
  module Flow
    module Resolvers
      class ActionResolver
      PRIORITY = {
        ron_agari: 1,
        daiminkan: 2,
        pon: 2,
        chi: 3
      }.freeze

      # 同じ優先度どうしは、from_seat（打牌・加槓した席）を渡せばその下家から順（頭はね）、
      # 渡さなければ seat 番号の若い順。
      # rule を渡すと、ロンが複数のときに double_ron・triple_ron_draw に従う:
      #   3 人のロンで triple_ron_draw なら { type: :sanchahou, seats: [...] }（三家和の流局）
      #   double_ron なら { type: :ron_agari, seat: 先頭, seats: [...] }（全員の和了）
      #   どちらでもなければ 1 人（rule を渡さないときと同じ）
      def self.resolve(pending_actions, from_seat: nil, rule: nil)
        return nil if pending_actions.nil? || pending_actions.empty?

        candidates = pending_actions.flat_map { |seat, actions| Array(actions).map { |action| action.merge(seat: seat) } }
        best = candidates.min_by { |action| [PRIORITY[action[:type].to_sym] || 99, turn_order(action[:seat], from_seat)] }
        return best unless rule && best && best[:type].to_sym == :ron_agari

        ron_seats = candidates.select { |action| action[:type].to_sym == :ron_agari }.map { |action| action[:seat] }.uniq
                              .sort_by { |seat| turn_order(seat, from_seat) }
        return best if ron_seats.size < 2
        return { type: :sanchahou, seats: ron_seats } if ron_seats.size >= 3 && rule.triple_ron_draw?
        return { type: :ron_agari, seat: best[:seat], seats: ron_seats } if rule.double_ron?

        best
      end

      def self.turn_order(seat, from_seat)
        from_seat.nil? ? seat : (seat - from_seat) % 4
      end
      private_class_method :turn_order
      end
    end
  end
end
