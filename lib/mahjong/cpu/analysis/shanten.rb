module Mahjong
  module Cpu
    module Analysis
      # 向聴数。tiles_34 は手の内の牌（副露を含まない）、melds は副露の数。
      #
      # 通常形は 8 - 2 x 面子 - 搭子 - 雀頭（面子と搭子は合わせて 4 - melds まで、
      # 副露は面子として数える）。七対子と国士無双は副露が無いときだけ数える。
      #
      # 通常形は萬子・筒子・索子・字牌の 4 つに分けて、それぞれの取り方
      # （面子・搭子・雀頭の数の組）を求めてから組み合わせる。1 つの色の取り方は
      # その色の牌の並びだけで決まるので、並びごとに覚えておく（受け入れの計算では
      # 同じ並びが何度も出てくる）。
      class Shanten
      MEMO_LIMIT = 50_000

      @memo = {}

      class << self
        def calculate(tiles_34, melds: 0)
          regular = regular_shanten(tiles_34, melds: melds)
          return regular unless melds.zero?

          [regular, chiitoitsu_shanten(tiles_34), kokushi_shanten(tiles_34)].min
        end

        def regular_shanten(tiles_34, melds: 0)
          cap = 4 - melds
          blocks = [
            block_options(tiles_34, 0, 9, true),
            block_options(tiles_34, 9, 9, true),
            block_options(tiles_34, 18, 9, true),
            block_options(tiles_34, 27, 7, false)
          ]

          best = 8
          blocks[0].each do |m0, t0, p0|
            blocks[1].each do |m1, t1, p1|
              next if p0 + p1 > 1

              blocks[2].each do |m2, t2, p2|
                next if p0 + p1 + p2 > 1

                blocks[3].each do |m3, t3, p3|
                  pair = p0 + p1 + p2 + p3
                  next if pair > 1

                  mentsu = [m0 + m1 + m2 + m3, cap].min
                  taatsu = [t0 + t1 + t2 + t3, cap - mentsu].min
                  shanten = 8 - (2 * (mentsu + melds)) - taatsu - pair
                  best = shanten if shanten < best
                end
              end
            end
          end
          best
        end

        def chiitoitsu_shanten(tiles_34)
          pairs = tiles_34.count { |count| count >= 2 }
          kinds = tiles_34.count(&:positive?)

          shanten = 6 - pairs
          shanten += [7 - kinds, 0].max if kinds < 7
          shanten
        end

        def kokushi_shanten(tiles_34)
          kinds = Tiles::TileSet::YAOCHU_INDICES.count { |i| tiles_34[i].positive? }
          pairs = Tiles::TileSet::YAOCHU_INDICES.count { |i| tiles_34[i] >= 2 }

          13 - kinds - (pairs.positive? ? 1 : 0)
        end

        private

        # 1 つの色（または字牌）の取り方: [[面子, 搭子, 雀頭], ...]。
        # 他の取り方に面子・搭子とも負けるもの（雀頭が同じとき）は除く。
        def block_options(tiles_34, base, size, sequences)
          counts = tiles_34[base, size]
          key = counts.reduce(sequences ? 1 : 2) { |acc, c| (acc * 5) + c }
          cached = @memo[key]
          return cached if cached

          found = {}
          search(counts, 0, 0, 0, 0, sequences, found)
          options = pareto(found.keys).freeze
          @memo.clear if @memo.size >= MEMO_LIMIT
          @memo[key] = options
        end

        def search(counts, index, mentsu, taatsu, pair, sequences, found)
          size = counts.size
          index += 1 while index < size && counts[index].zero?
          if index >= size
            found[[mentsu, taatsu, pair]] = true
            return
          end

          if counts[index] >= 3
            counts[index] -= 3
            search(counts, index, mentsu + 1, taatsu, pair, sequences, found)
            counts[index] += 3
          end

          if sequences && index <= 6 && counts[index + 1].positive? && counts[index + 2].positive?
            counts[index] -= 1
            counts[index + 1] -= 1
            counts[index + 2] -= 1
            search(counts, index, mentsu + 1, taatsu, pair, sequences, found)
            counts[index] += 1
            counts[index + 1] += 1
            counts[index + 2] += 1
          end

          if counts[index] >= 2
            counts[index] -= 2
            search(counts, index, mentsu, taatsu, 1, sequences, found) if pair.zero?
            search(counts, index, mentsu, taatsu + 1, pair, sequences, found)
            counts[index] += 2
          end

          if sequences && index <= 7 && counts[index + 1].positive?
            counts[index] -= 1
            counts[index + 1] -= 1
            search(counts, index, mentsu, taatsu + 1, pair, sequences, found)
            counts[index] += 1
            counts[index + 1] += 1
          end

          if sequences && index <= 6 && counts[index + 2].positive?
            counts[index] -= 1
            counts[index + 2] -= 1
            search(counts, index, mentsu, taatsu + 1, pair, sequences, found)
            counts[index] += 1
            counts[index + 2] += 1
          end

          counts[index] -= 1
          search(counts, index, mentsu, taatsu, pair, sequences, found)
          counts[index] += 1
        end

        def pareto(options)
          options.reject do |a|
            options.any? { |b| !b.equal?(a) && b[2] == a[2] && b[0] >= a[0] && b[1] >= a[1] && b != a }
          end
        end
      end
      end
    end
  end
end
