module Mahjong
  module Flow
    module Validators
      class ActionValidator
      ValidationResult = Data.define(:valid, :error) do
        def valid?
          valid
        end
      end

      def self.valid?(state:, action:, rule:)
        validate(state:, action:, rule:).valid?
      end

      def self.validate(state:, action:, rule:)
        type = action[:type]&.to_sym
        return invalid("action type is required") unless type

        case type
        when :tsumo
          return invalid("phase must be tsumo") unless state.phase == :tsumo
          valid
        when :dahai
          return invalid("phase must be dahai") unless state.phase == :dahai
          return invalid("seat mismatch") unless action[:seat] == state.current_seat
          return invalid("tile is required") if missing_value?(action[:tile])
          return invalid("tile not in hand") unless state.hands[state.current_seat].include?(action[:tile])
          valid
        when :skip
          return invalid("phase must be naki_wait") unless state.phase == :naki_wait
          return invalid("seat is required") if action[:seat].nil?
          return invalid("seat has no pending action") unless state.pending_actions.key?(action[:seat])
          valid
        when :pon, :chi
          return invalid("phase must be naki_wait") unless state.phase == :naki_wait
          return invalid("seat is required") if action[:seat].nil?
          return invalid("seat has no pending action") unless state.pending_actions.key?(action[:seat])
          return invalid("riichi player cannot call") if state.riichi_flags[action[:seat]]
          return invalid("action is not pending") unless state.pending_actions[action[:seat]].any? { |a| a[:type].to_sym == type }
          return invalid("higher priority action exists") unless highest_priority_action?(state, action)
          valid
        when :riichi
          return invalid("phase must be dahai") unless state.phase == :dahai
          return invalid("seat mismatch") unless action[:seat] == state.current_seat
          return invalid("tile is required") if missing_value?(action[:tile])
          return invalid("cannot riichi") unless Rounds::RoundFlow.can_riichi?(state, state.current_seat, rule)
          return invalid("tile is not riichi candidate") unless Rounds::RoundFlow.riichi_dahai_candidates(state, state.current_seat).include?(action[:tile])
          valid
        when :ankan
          return invalid("phase must be dahai") unless state.phase == :dahai
          return invalid("seat mismatch") unless action[:seat] == state.current_seat
          return invalid("tile is required") if missing_value?(action[:tile])
          return invalid("cannot ankan") unless Rounds::RoundFlow.ankan_candidates(state, state.current_seat, rule).include?(action[:tile])
          valid
        when :kakan
          return invalid("phase must be dahai") unless state.phase == :dahai
          return invalid("seat mismatch") unless action[:seat] == state.current_seat
          return invalid("tile is required") if missing_value?(action[:tile])
          return invalid("cannot kakan") unless Rounds::RoundFlow.kakan_candidates(state, state.current_seat).include?(action[:tile])
          valid
        when :daiminkan, :ron_agari
          return invalid("phase must be naki_wait") unless state.phase == :naki_wait
          return invalid("seat is required") if action[:seat].nil?
          return invalid("seat has no pending action") unless state.pending_actions.key?(action[:seat])
          return invalid("riichi player cannot call") if type == :daiminkan && state.riichi_flags[action[:seat]]
          return invalid("action is not pending") unless state.pending_actions[action[:seat]].any? { |a| a[:type].to_sym == type }
          return invalid("higher priority action exists") unless highest_priority_action?(state, action)
          if type == :ron_agari
            agari_tile = state.chankan_tile || state.last_dahai&.dig(:tile)
            return invalid("cannot ron agari") unless agari_tile && Rounds::RoundFlow.can_ron_agari?(state, action[:seat], agari_tile, rule)
          end
          valid
        when :tsumo_agari
          return invalid("phase must be dahai") unless state.phase == :dahai
          return invalid("seat mismatch") unless action[:seat] == state.current_seat
          return invalid("cannot tsumo agari") unless Rounds::RoundFlow.can_tsumo_agari?(state, state.current_seat, rule)
          valid
        when :kyuushu_kyuuhai
          return invalid("phase must be dahai") unless state.phase == :dahai
          return invalid("seat mismatch") unless action[:seat] == state.current_seat
          return invalid("cannot kyuushu_kyuuhai") unless Rounds::RoundFlow.can_kyuushu?(state, state.current_seat)
          valid
        else
          invalid("unsupported action: #{type}")
        end
      end

      def self.valid
        ValidationResult.new(valid: true, error: nil)
      end

      def self.invalid(message)
        ValidationResult.new(valid: false, error: message)
      end

      def self.highest_priority_action?(state, action)
        resolved = Resolvers::ActionResolver.resolve(state.pending_actions, from_seat: state.last_dahai&.dig(:seat))
        return false unless resolved

        resolved[:seat] == action[:seat] && resolved[:type].to_sym == action[:type].to_sym
      end

      def self.missing_value?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
      end
      private_class_method :missing_value?
    end
    end
  end
end
