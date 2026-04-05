module Mahjong
  module Scoring
    module Judges
      class AgariJudge
        # 和了形か判定する（通常形 / 七対子 / 国士無双）
        #
        # @param tiles_34 [Array<Integer>] 手牌14枚の34配列
        # @return [Boolean]
        def self.agari?(tiles_34)
          regular_agari?(tiles_34) || chiitoitsu?(tiles_34) || kokushi?(tiles_34)
        end

        def self.regular_agari?(tiles_34)
          Scoring::Parsers::HandParser.parse(tiles_34).any?
        end

        def self.chiitoitsu?(tiles_34)
          pairs = tiles_34.count { |c| c >= 2 }
          pairs == 7 && tiles_34.all? { |c| c <= 2 }
        end

        def self.kokushi?(tiles_34)
          yaochu = Tiles::TileSet::YAOCHU_INDICES
          has_all = yaochu.all? { |i| tiles_34[i] >= 1 }
          has_pair = yaochu.any? { |i| tiles_34[i] >= 2 }
          total = yaochu.sum { |i| tiles_34[i] }
          has_all && has_pair && total == 14
        end

        def self.all_forms(tiles_34)
          forms = []

          Scoring::Parsers::HandParser.parse(tiles_34).each do |parsed|
            forms << AgariForm.new(type: :regular, parsed_hand: parsed)
          end

          if chiitoitsu?(tiles_34)
            pairs = (0...34).select { |i| tiles_34[i] >= 2 }
            forms << AgariForm.new(type: :chiitoitsu, pair_indices: pairs)
          end

          if kokushi?(tiles_34)
            pair_idx = Tiles::TileSet::YAOCHU_INDICES.find { |i| tiles_34[i] >= 2 }
            forms << AgariForm.new(type: :kokushi, kokushi_pair_index: pair_idx)
          end

          forms
        end
      end

      class AgariForm
        attr_reader :type, :parsed_hand, :pair_indices, :kokushi_pair_index

        def initialize(type:, parsed_hand: nil, pair_indices: nil, kokushi_pair_index: nil)
          @type = type
          @parsed_hand = parsed_hand
          @pair_indices = pair_indices
          @kokushi_pair_index = kokushi_pair_index
          freeze
        end

        def regular? = type == :regular
        def chiitoitsu? = type == :chiitoitsu
        def kokushi? = type == :kokushi
      end
    end
  end
end
