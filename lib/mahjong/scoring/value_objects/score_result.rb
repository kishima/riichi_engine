module Mahjong
  module Scoring
    module ValueObjects
      class ScoreResult
      # pao: 包（責任払い）の分 [{ seat: 責任を負う席, base_points: その分の基本点 }]。空なら包なし。
      attr_reader :fu, :han, :base_points, :level, :is_oya,
                  :agari_type, :payments, :total, :kyoutaku_bonus, :honba, :is_yakuman, :pao, :pao_honba

      def initialize(**attrs)
        @pao = []
        attrs.each { |k, v| instance_variable_set(:"@#{k}", v) }
        @pao ||= []
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

      # 包があれば、包の分はツモなら責任者が全額（積み棒も）、ロンなら放銃者と責任者が
      # 半分ずつ（積み棒は放銃者、pao_honba が "liable" なら責任者）。残りの分はふつうに払う。
      def score_changes(winner_seat:, loser_seat:, oya_seat:)
        return pao_score_changes(winner_seat:, loser_seat:, oya_seat:) if pao.any?

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

      private

      def pao_score_changes(winner_seat:, loser_seat:, oya_seat:)
        changes = Hash.new(0)
        pay = lambda do |from, amount|
          changes[from] -= amount
          changes[winner_seat] += amount
        end
        ron_value = ->(base) { ((base * (is_oya ? 6 : 4)) + 99) / 100 * 100 }
        rest = base_points - pao.sum { |part| part[:base_points] }

        pao.each do |part|
          value = ron_value.call(part[:base_points])
          if agari_type == :tsumo || part[:seat] == loser_seat
            pay.call(part[:seat], value)
          else
            pay.call(part[:seat], value / 2)
            pay.call(loser_seat, value - (value / 2))
          end
        end

        if agari_type == :tsumo
          if rest.positive?
            4.times do |seat|
              next if seat == winner_seat

              factor = is_oya || seat == oya_seat ? 2 : 1
              pay.call(seat, ((rest * factor) + 99) / 100 * 100)
            end
          end
          pay.call(pao.first[:seat], honba.to_i * 300)
        else
          pay.call(loser_seat, ron_value.call(rest)) if rest.positive?
          pay.call(pao_honba == "liable" ? pao.first[:seat] : loser_seat, honba.to_i * 300)
        end

        changes[winner_seat] += kyoutaku_bonus
        changes
      end
      end
    end
  end
end
