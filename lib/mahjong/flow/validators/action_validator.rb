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
        when :ron_agari
          return validate_multiple_ron(state, action, rule) if action[:seats]
          validate_call(state, action, rule, type)
        when :sanchahou
          validate_sanchahou(state, action, rule)
        when :daiminkan
          validate_call(state, action, rule, type)
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

      def self.validate_call(state, action, rule, type)
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
      end
      private_class_method :validate_call

      # 2 人以上のロン（seats: 和了る席の一覧）。double_ron のときだけ受け、3 人は
      # triple_ron_draw が偽のときだけ受ける（真なら三家和の :sanchahou を使う）。
      def self.validate_multiple_ron(state, action, rule)
        seats = Array(action[:seats])
        return invalid("phase must be naki_wait") unless state.phase == :naki_wait
        return invalid("seats must be distinct") unless seats.uniq.size == seats.size
        return invalid("seat must be one of seats") if action[:seat] && !seats.include?(action[:seat])
        return invalid("single ron must not use seats") if seats.size < 2
        return invalid("double ron is not allowed") unless rule.double_ron?
        return invalid("three rons are sanchahou") if seats.size >= 3 && rule.triple_ron_draw?
        return invalid("every seat must be able to ron") unless seats.all? { |seat| ron_pending?(state, seat, rule) }

        valid
      end
      private_class_method :validate_multiple_ron

      # 三家和: 3 人がロンを宣言した。triple_ron_draw のときだけ。
      def self.validate_sanchahou(state, action, rule)
        seats = Array(action[:seats])
        return invalid("phase must be naki_wait") unless state.phase == :naki_wait
        return invalid("sanchahou is not a draw by the rule") unless rule.triple_ron_draw?
        return invalid("sanchahou needs three seats") unless seats.uniq.size == 3
        return invalid("every seat must be able to ron") unless seats.all? { |seat| ron_pending?(state, seat, rule) }

        valid
      end
      private_class_method :validate_sanchahou

      def self.ron_pending?(state, seat, rule)
        return false unless state.pending_actions.key?(seat)
        return false unless state.pending_actions[seat].any? { |a| a[:type].to_sym == :ron_agari }

        agari_tile = state.chankan_tile || state.last_dahai&.dig(:tile)
        agari_tile && Rounds::RoundFlow.can_ron_agari?(state, seat, agari_tile, rule)
      end
      private_class_method :ron_pending?

      def self.valid
        ValidationResult.new(valid: true, error: nil)
      end

      def self.invalid(message)
        ValidationResult.new(valid: false, error: message)
      end

      def self.highest_priority_action?(state, action)
        resolved = Resolvers::ActionResolver.resolve(state.pending_actions)
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
