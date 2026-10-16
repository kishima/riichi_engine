module Mahjong
  module Cpu
    module Analysis
      # 鳴いた手の役の筋。門前でない手はリーチも門前自摸も付かないので、副露から見て残っている
      # 役の筋に沿って手を進めないと、テンパイしても和了れない。
      #
      # 筋は副露だけで決める:
      #   :yakuhai          役牌（三元牌・自風・場風）の刻子か槓子がある。和了の形を問わず役がある
      #   :tanyao           副露に么九牌が無い（喰い断があるときだけ）
      #   :honitsu_m/p/s    副露がその色と字牌だけ（混一色・清一色）
      #   :toitoi           副露がすべて刻子か槓子
      # 筋ごとの向聴数は、その筋で使えない牌を手から除いて数える（対々和は対子と刻子の数で数える）。
      class YakuPlan
        HONITSU = { honitsu_m: "m", honitsu_p: "p", honitsu_s: "s" }.freeze
        SUIT_BASE = { "m" => 0, "p" => 9, "s" => 18 }.freeze
        YAOCHU = [0, 8, 9, 17, 18, 26, *27..33].freeze

        class << self
          # 副露（fuuros）から見て残っている筋。jikaze・bakaze は "ton" などの名前。
          def plans(fuuros, jikaze:, bakaze:, kuitan: true)
            fuuros = Array(fuuros)
            tiles = fuuros.map(&:tiles)
            plans = []
            plans << :yakuhai if fuuros.any? { |f| !f.chi? && yakuhai?(f.tiles.first, jikaze, bakaze) }
            plans << :tanyao if kuitan && tiles.all? { |ts| ts.none?(&:yaochu?) }
            HONITSU.each do |plan, suit|
              plans << plan if tiles.all? { |ts| ts.all? { |t| t.jihai? || t.suit == suit } }
            end
            plans << :toitoi if fuuros.none?(&:chi?)
            plans
          end

          # 席 seat の副露から見た筋（fuuros を渡すとその副露で）。門前の手（暗槓だけを含む）は nil。
          # rule は喰い断の有無を見る（省略すると喰い断あり）。
          def seat_plans(state, seat, rule, fuuros: nil)
            return nil if fuuros.nil? && menzen?(state, seat)

            plans(fuuros || Array(state.fuuros && state.fuuros[seat]), **winds(state, seat), kuitan: rule.nil? || rule.kuitan?)
          end

          def menzen?(state, seat)
            flags = state.menzen_flags
            flags.nil? || flags[seat] != false
          end

          def winds(state, seat)
            { jikaze: Tiles::Tile::KAZE_NAMES[((seat - state.oya_seat.to_i) % 4) + 1], bakaze: state.bakaze.to_s }
          end

          # 筋 plan に沿った向聴数。tiles_34 は手の内の牌、melds は副露の数。
          def shanten(plan, tiles_34, melds)
            case plan
            when :yakuhai then Shanten.regular_shanten(tiles_34, melds: melds)
            when :tanyao then Shanten.regular_shanten(without(tiles_34, YAOCHU), melds: melds)
            when :toitoi then toitoi_shanten(tiles_34, melds)
            else
              base = SUIT_BASE.fetch(HONITSU.fetch(plan))
              others = (0..26).reject { |i| i.between?(base, base + 8) }
              Shanten.regular_shanten(without(tiles_34, others), melds: melds)
            end
          end

          # いちばん近い筋の向聴数。筋が無ければ nil。
          def best_shanten(plans, tiles_34, melds)
            plans.map { |plan| shanten(plan, tiles_34, melds) }.min
          end

          def yakuhai?(tile, jikaze, bakaze)
            return false unless tile.jihai?
            return true if tile.sangenpai?

            name = Tiles::Tile::KAZE_NAMES[tile.number]
            name == jikaze.to_s || name == bakaze.to_s
          end

          private

          def without(tiles_34, indices)
            out = tiles_34.dup
            indices.each { |i| out[i] = 0 }
            out
          end

          # 対々和: 残りの (4 - melds) 個の刻子と雀頭を、手の刻子・対子から作る。
          def toitoi_shanten(tiles_34, melds)
            slots = 4 - melds
            triplets = [tiles_34.count { |c| c >= 3 }, slots].min
            pairs = tiles_34.count { |c| c == 2 } + (tiles_34.count { |c| c >= 3 } - triplets)
            open_slots = slots - triplets
            head = pairs.positive? ? 1 : 0
            to_triplets = [pairs - head, open_slots].min
            (2 * open_slots) - to_triplets + (1 - head) - 1
          end
        end
      end
    end
  end
end
