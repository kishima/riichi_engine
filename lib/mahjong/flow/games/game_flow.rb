module Mahjong
  module Flow
    module Games
      # 半荘/東風の局間進行を管理する。
      class GameFlow
    # 次局に進むべきか、ゲーム終了かを判定する
    # @param progress_snapshot [Mahjong::Snapshots::GameProgressSnapshot]
    # @param round_end_info [Hash]
    # @param rule [RuleConfig]
    # @return [GameFlowResult]
    def self.judge_next(progress_snapshot:, round_end_info:, rule:)
      scores = progress_snapshot.scores

      if rule.tobi? && scores.values.any?(&:negative?)
        return Results::GameFlowResult.new(
          action: :game_end, reason: :tobi,
          next_bakaze: nil, next_kyoku: nil, next_honba: nil, next_oya_index: nil, renchan: false
        )
      end

      info = normalize_round_end_info(round_end_info)
      renchan = renchan?(progress_snapshot, info)
      next_honba = calc_next_honba(progress_snapshot, info, renchan)

      if renchan
        if all_last_oya_agari?(progress_snapshot, info, scores, rule)
          return Results::GameFlowResult.new(
            action: :game_end, reason: :all_last_oya_agari,
            next_bakaze: nil, next_kyoku: nil, next_honba: nil, next_oya_index: nil, renchan: true
          )
        end

        return Results::GameFlowResult.new(
          action: :next_round, reason: :renchan,
          next_bakaze: progress_snapshot.bakaze, next_kyoku: progress_snapshot.kyoku, next_honba: next_honba, next_oya_index: progress_snapshot.oya_index, renchan: true
        )
      end

      next_oya_index = (progress_snapshot.oya_index + 1) % 4
      next_bakaze = progress_snapshot.bakaze
      next_kyoku = progress_snapshot.kyoku + 1

      if next_kyoku > 4
        next_kyoku = 1
        next_bakaze = next_bakaze_value(progress_snapshot.bakaze)
      end

      if should_end_game?(next_bakaze, scores, rule)
        return Results::GameFlowResult.new(
          action: :game_end, reason: :normal_end,
          next_bakaze: nil, next_kyoku: nil, next_honba: nil, next_oya_index: nil, renchan: false
        )
      end

      Results::GameFlowResult.new(
        action: :next_round, reason: :oya_nagare,
        next_bakaze: next_bakaze, next_kyoku: next_kyoku, next_honba: next_honba, next_oya_index: next_oya_index, renchan: false
      )
    end

    # 最終結果の計算（ウマ・オカ適用）
    # @param final_result_snapshot [Mahjong::Snapshots::FinalResultSnapshot]
    # @param rule [RuleConfig]
    # @return [Array<FinalResult>]
    def self.calculate_final_result(final_result_snapshot:, rule:)
      scores = final_result_snapshot.scores
      base_results = Results::GameResult.calculate(scores:, rule:)
      by_seat = final_result_snapshot.players_by_seat

      base_results.map do |result|
        gp = by_seat[result.seat]
        Results::FinalResult.new(
          seat: result.seat,
          player_id: gp[:player_id],
          name: gp[:name],
          rank: result.rank,
          score: result.score,
          adjusted_score: result.adjusted_score,
          point: result.point
        )
      end
    end

    def self.calculate_tenpai_payments(tenpai_seats)
      changes = { 0 => 0, 1 => 0, 2 => 0, 3 => 0 }
      count = tenpai_seats.size
      return changes if count.zero? || count == 4

      receive, pay = case count
                     when 1 then [3000, 1000]
                     when 2 then [1500, 1500]
                     when 3 then [1000, 3000]
                     end

      4.times do |seat|
        changes[seat] = tenpai_seats.include?(seat) ? receive : -pay
      end

      changes
    end

    def self.renchan?(progress_snapshot, round_end_info)
      case round_end_info.result_type
      when :tsumo_agari, :ron_agari, :tsumo, :ron
        round_end_info.winners.any? { |w| w[:seat] == progress_snapshot.oya_index }
      when :ryuukyoku
        round_end_info.tenpai_seats.include?(progress_snapshot.oya_index)
      when :draw_abortive, :kyuushu_kyuuhai, :sanchahou
        true
      else
        false
      end
    end

    def self.calc_next_honba(progress_snapshot, round_end_info, renchan)
      case round_end_info.result_type
      when :tsumo_agari, :ron_agari, :tsumo, :ron
        renchan ? progress_snapshot.honba + 1 : 0
      when :ryuukyoku, :draw_abortive, :kyuushu_kyuuhai, :sanchahou
        progress_snapshot.honba + 1
      else
        0
      end
    end

    def self.next_bakaze_value(current)
      case current
      when "ton" then "nan"
      when "nan" then "sha"
      else current
      end
    end

    def self.should_end_game?(next_bakaze, scores, rule)
      case rule.game_type
      when "tonpuu", "tonpuusen"
        next_bakaze == "nan"
      when "hanchan"
        if next_bakaze == "sha"
          return false if rule.nishi_iri? && scores.values.max < rule.nishi_iri_threshold

          return true
        end
        false
      else
        false
      end
    end

    def self.all_last_oya_agari?(progress_snapshot, round_end_info, scores, rule)
      is_all_last = (progress_snapshot.bakaze == "nan" && progress_snapshot.kyoku == 4 && rule.game_type == "hanchan") ||
                    (progress_snapshot.bakaze == "ton" && progress_snapshot.kyoku == 4 && %w[tonpuu tonpuusen].include?(rule.game_type))
      return false unless is_all_last
      return false unless round_end_info.winners.any? { |winner| winner[:seat] == progress_snapshot.oya_index }

      scores[progress_snapshot.oya_index] == scores.values.max && scores[progress_snapshot.oya_index].positive?
    end

    def self.normalize_round_end_info(info)
      return info if info.is_a?(Results::RoundEndInfo)

      result_type = info[:result_type] || info[:type]
      winners = info[:winners]
      losers = info[:losers]

      if winners.nil? && info.key?(:winner_seat)
        winners = info[:winner_seat].nil? ? [] : [{ seat: info[:winner_seat] }]
      end

      if losers.nil? && info.key?(:loser_seat)
        losers = info[:loser_seat].nil? ? [] : [{ seat: info[:loser_seat] }]
      end

      Results::RoundEndInfo.new(
        result_type: result_type,
        winners: winners,
        losers: losers,
        tenpai_seats: info[:tenpai_seats],
        draw_reason: info[:draw_reason],
        score_changes: info[:score_changes]
      )
    end
      end
    end
  end
end
