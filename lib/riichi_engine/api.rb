module RiichiEngine
  module API
    InvalidActionError = Mahjong::Errors::InvalidActionError
    EngineError = Mahjong::Errors::EngineError

    def self.setup_round(game_snapshot:, rule:, seed: nil)
      Mahjong::Flow::Rounds::RoundFlow.setup(game_snapshot:, rule:, seed:)
    end

    def self.apply_round_action(state:, action:, rule:)
      Mahjong::Flow::Rounds::RoundFlow.apply_action(state:, action:, rule:)
    end

    def self.available_round_actions(state:, seat:, rule:)
      Mahjong::Flow::Rounds::RoundFlow.available_actions(state:, seat:, rule:)
    end

    def self.resolve_pending_action(pending_actions)
      Mahjong::Flow::Resolvers::ActionResolver.resolve(pending_actions)
    end

    def self.judge_next_game_round(progress_snapshot:, round_end_info:, rule:)
      Mahjong::Flow::Games::GameFlow.judge_next(progress_snapshot:, round_end_info:, rule:)
    end

    def self.calculate_final_results(final_result_snapshot:, rule:)
      Mahjong::Flow::Games::GameFlow.calculate_final_result(final_result_snapshot:, rule:)
    end

    def self.calculate_ranked_results(scores:, rule:)
      Mahjong::Results::GameResult.calculate(scores:, rule:)
    end

    def self.calculate_tenpai_payments(tenpai_seats)
      Mahjong::Flow::Games::GameFlow.calculate_tenpai_payments(tenpai_seats)
    end

    def self.calculate_nagashi_mangan_payments(nagashi_seats, oya_seat:)
      Mahjong::Flow::Games::GameFlow.calculate_nagashi_mangan_payments(nagashi_seats, oya_seat:)
    end

    def self.tenpai_seats(state)
      4.times.select { |seat| Mahjong::Scoring::Judges::MachiJudge.tenpai?(state.hands[seat].to_34) }
    end

    def self.evaluate_win(state:, seat:, agari_type:, agari_tile:, rule:, extra_flags:, snapshot:)
      Mahjong::Scoring::Evaluators::WinEvaluator.evaluate(
        state:,
        seat:,
        agari_type:,
        agari_tile:,
        rule:,
        extra_flags:,
        snapshot:
      )
    end

    def self.agari?(tiles_34)
      Mahjong::Scoring::Judges::AgariJudge.agari?(tiles_34)
    end

    def self.deserialize_round_state(json)
      Mahjong::State::RoundState.from_json(json)
    end
  end
end
