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

      def self.resolve(pending_actions)
        return nil if pending_actions.nil? || pending_actions.empty?

        pending_actions
          .flat_map { |seat, actions| Array(actions).map { |action| action.merge(seat: seat) } }
          .min_by { |action| [PRIORITY[action[:type].to_sym] || 99, action[:seat]] }
      end
      end
    end
  end
end
