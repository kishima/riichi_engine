module Mahjong
  module Results
    class GameResult
      def self.calculate(scores:, rule:)
        ranking = scores.sort_by { |seat, score| [-score, seat] }
        uma = rule.uma_values
        oka_total = (rule.oka_origin - rule.initial_score) * 4

        ranking.each_with_index.map do |(seat, score), index|
          adjusted = score - rule.oka_origin + uma[index]
          adjusted += oka_total if index.zero?

          Results::FinalResult.new(
            seat: seat,
            player_id: nil,
            name: nil,
            rank: index + 1,
            score: score,
            adjusted_score: adjusted,
            point: (adjusted / 1000.0).round(1)
          )
        end
      end
    end
  end
end
