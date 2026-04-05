module Mahjong
  module Scoring
    module ValueObjects
      class ScoreResult
      attr_reader :fu, :han, :base_points, :level, :is_oya,
                  :agari_type, :payments, :total, :kyoutaku_bonus, :honba, :is_yakuman

      def initialize(**attrs)
        attrs.each { |k, v| instance_variable_set(:"@#{k}", v) }
      end

      def display
        parts = []
        parts << "#{fu}符" if fu && level.empty?
        parts << "#{han}翻" if han && !is_yakuman
        parts << level unless level.empty?
        parts << score_text
        parts.join(" ")
      end

      def score_text
        if agari_type == :tsumo
          is_oya ? "#{payments[:ko_pays]}点オール" : "#{payments[:ko_pays]}/#{payments[:oya_pays]}点"
        else
          "#{payments[:ron_pay]}点"
        end
      end

      def score_changes(winner_seat:, loser_seat:, oya_seat:)
        changes = Hash.new(0)

        if agari_type == :tsumo
          4.times do |seat|
            next if seat == winner_seat

            pay = if is_oya
                    payments[:ko_pays]
                  elsif seat == oya_seat
                    payments[:oya_pays]
                  else
                    payments[:ko_pays]
                  end
            changes[seat] -= pay
            changes[winner_seat] += pay
          end
        else
          changes[loser_seat] -= payments[:ron_pay]
          changes[winner_seat] += payments[:ron_pay]
        end

        changes[winner_seat] += kyoutaku_bonus
        changes
      end
      end
    end
  end
end
