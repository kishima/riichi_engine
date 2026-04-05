module Mahjong
  module Cpu
    module Judges
      class NakiJudge
      def self.judge(naki_options:, state:, seat:, level:)
        ron = naki_options.find { |option| option[:type] == :ron_agari }
        return ron if ron

        case level
        when 1 then judge_easy(naki_options)
        when 2 then judge_normal(naki_options, state, seat)
        when 3 then judge_hard(naki_options, state, seat)
        else judge_normal(naki_options, state, seat)
        end
      end

      private_class_method def self.judge_easy(options)
        pon = options.find { |option| option[:type] == :pon }
        return nil unless pon

        tile = Tiles::Tile.new(pon[:tiles].first)
        tile.sangenpai? ? pon : nil
      end

      private_class_method def self.judge_normal(options, state, seat)
        hand = state.hands[seat]
        current_shanten = Analysis::Shanten.calculate(hand.to_34)

        options.each do |option|
          next if option[:type] == :skip
          next if should_keep_menzen?(hand, current_shanten)

          return option if simulate_naki_shanten(hand, option) < current_shanten
        end

        nil
      end

      private_class_method def self.judge_hard(options, state, seat)
        judge_normal(options, state, seat)
      end

      private_class_method def self.simulate_naki_shanten(hand, naki_option)
        tiles = Array(naki_option[:tiles]).map { |tile| Tiles::Tile.new(tile) }

        case naki_option[:type]
        when :pon, :chi
          Analysis::Shanten.calculate(hand.remove_tiles(tiles).to_34) - 2
        else
          Analysis::Shanten.calculate(hand.to_34)
        end
      end

      private_class_method def self.should_keep_menzen?(_hand, shanten)
        shanten <= 1
      end
      end
    end
  end
end
