module Mahjong
  module Scoring
    module Judges
      class MachiJudge
      MachiResult = Data.define(:tile_index, :machi_type, :agari_form)

      def self.find_machi(tiles_34)
        results = []
        work = tiles_34.dup

        34.times do |i|
          next if work[i] >= 4

          work[i] += 1
          if AgariJudge.agari?(work)
            forms = AgariJudge.all_forms(work)
            determine_machi_types(work, i, forms).each do |mt|
              results << MachiResult.new(tile_index: i, machi_type: mt[:type], agari_form: mt[:form])
            end
          end
          work[i] -= 1
        end

        results
      end

      def self.tenpai?(tiles_34)
        find_machi(tiles_34).any?
      end

      def self.machi_tile_indices(tiles_34)
        find_machi(tiles_34).map(&:tile_index).uniq
      end

      private

      def self.determine_machi_types(_tiles_34, agari_idx, forms)
        results = []

        forms.each do |form|
          case form.type
          when :chiitoitsu, :kokushi
            results << { type: :tanki, form: form }
          when :regular
            results << { type: regular_machi_type(form.parsed_hand, agari_idx), form: form }
          end
        end

        results
      end

      def self.regular_machi_type(parsed, agari_idx)
        return :tanki if parsed.jantou_index == agari_idx

        parsed.mentsu_indices.each do |m|
          case m[:type]
          when :koutsu
            return :shanpon if m[:index] == agari_idx
          when :shuntsu
            base = m[:index]
            next unless agari_idx >= base && agari_idx <= base + 2

            pos = agari_idx - base
            suit_pos = base % 9

            return :kanchan if pos == 1
            return :penchan if pos == 0 && suit_pos == 6
            return :penchan if pos == 2 && suit_pos == 0
            return :ryanmen
          end
        end

        :tanki
      end
      end
    end
  end
end
