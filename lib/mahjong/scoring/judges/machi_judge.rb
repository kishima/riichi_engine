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
            regular_machi_types(form.parsed_hand, agari_idx).each do |type|
              results << { type: type, form: form }
            end
          end
        end

        results
      end

      # 同じ和了形でも、和了牌が雀頭と面子のどれに入るかで待ちが変わる（55m + 345m の 5m は
      # 単騎でも両面でもある）。取り得る待ちをすべて返す。
      def self.regular_machi_types(parsed, agari_idx)
        types = []
        types << :tanki if parsed.jantou_index == agari_idx

        parsed.mentsu_indices.each do |m|
          case m[:type]
          when :koutsu
            types << :shanpon if m[:index] == agari_idx
          when :shuntsu
            base = m[:index]
            next unless agari_idx >= base && agari_idx <= base + 2

            pos = agari_idx - base
            suit_pos = base % 9

            types << if pos == 1
                       :kanchan
                     elsif (pos == 0 && suit_pos == 6) || (pos == 2 && suit_pos == 0)
                       :penchan
                     else
                       :ryanmen
                     end
          end
        end

        types.empty? ? [:tanki] : types.uniq
      end
      end
    end
  end
end
