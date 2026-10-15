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
      def self.resolve(pending_actions, from_seat: nil)
        return nil if pending_actions.nil? || pending_actions.empty?

        pending_actions
          .flat_map { |seat, actions| Array(actions).map { |action| action.merge(seat: seat) } }
          .min_by { |action| [PRIORITY[action[:type].to_sym] || 99, turn_order(action[:seat], from_seat)] }
      end

      def self.turn_order(seat, from_seat)
        from_seat.nil? ? seat : (seat - from_seat) % 4
      end
      private_class_method :turn_order
      end
    end
  end
end
