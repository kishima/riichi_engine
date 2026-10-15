require_relative "../../../spec_helper"

RSpec.describe Mahjong::Cpu::Analysis::Shanten do
  def hand_34(str)
    Mahjong::State::Hand.new(tiles(str)).to_34
  end

  describe ".calculate" do
    it "和了形は -1 を返す" do
      expect(described_class.calculate(hand_34("1m 2m 3m 1p 2p 3p 1s 2s 3s 7s 8s 9s 7z 7z"))).to eq(-1)
    end

    it "テンパイ形は 0 を返す" do
      expect(described_class.calculate(hand_34("1m 2m 3m 1p 2p 3p 1s 2s 3s 7s 8s 9s 7z"))).to eq(0)
    end

    it "イーシャンテン形は 1 を返す" do
      expect(described_class.calculate(hand_34("1m 2m 3m 1p 2p 3p 1s 2s 7s 8s 7z 7z 7z"))).to eq(1)
    end

    it "七対子の向聴数を返す" do
      expect(described_class.calculate(hand_34("1m 1m 2m 2m 3p 3p 4p 4p 5s 5s 6s 6s 7z"))).to eq(0)
    end

    it "国士無双の向聴数を返す" do
      expect(described_class.calculate(hand_34("1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z"))).to eq(0)
    end
  end

  describe ".calculate with melds" do
    it "副露 1 つと手の内の 3 面子・単騎はテンパイ" do
      expect(described_class.calculate(hand_34("1m 2m 3m 4p 5p 6p 7s 8s 9s 1z"), melds: 1)).to eq(0)
    end

    it "副露 1 つで 4 面子 1 雀頭がそろえば和了形（-1）" do
      expect(described_class.calculate(hand_34("1m 2m 3m 4p 5p 6p 7s 8s 9s 1z 1z"), melds: 1)).to eq(-1)
    end

    it "副露 3 つと単騎はテンパイ、浮き牌 2 枚は 1 向聴" do
      expect(described_class.calculate(hand_34("5z"), melds: 4)).to eq(0)
      expect(described_class.calculate(hand_34("2m 3m 9p 1z"), melds: 3)).to eq(1)
    end

    it "副露があると七対子・国士無双は数えない" do
      # 対子 5 つ: 七対子なら 1 向聴だが、副露があるので通常形の 2 向聴
      expect(described_class.calculate(hand_34("1m 1m 2m 2m 3p 3p 4p 4p 5s 5s"), melds: 1)).to eq(2)
      expect(described_class.calculate(hand_34("1m 9m 1p 9p 1s 9s 1z 2z 3z 4z"), melds: 1)).to eq(6)
    end

    it "melds を省くと 0（門前）として数える" do
      hand = hand_34("1m 2m 3m 4p 5p 6p 7s 8s 9s 1z")
      expect(described_class.calculate(hand)).to eq(described_class.calculate(hand, melds: 0))
    end
  end

  # 手全体を 1 度に探す素直な数え方（0.1.0 の探索に副露の数を加えたもの）と比べる。
  describe "reference search" do
    def reference(tiles_34, melds)
      cap = 4 - melds
      best = 8
      walk = lambda do |t, i, m, ta, pr|
        i += 1 while i < 34 && t[i].zero?
        if i >= 34
          mm = [m, cap].min
          v = 8 - (2 * (mm + melds)) - [ta, cap - mm].min - pr
          best = v if v < best
          return
        end
        suit = i < 27
        if t[i] >= 3
          t[i] -= 3; walk.(t, i, m + 1, ta, pr); t[i] += 3
        end
        if suit && i % 9 <= 6 && t[i + 1].positive? && t[i + 2].positive?
          t[i] -= 1; t[i + 1] -= 1; t[i + 2] -= 1
          walk.(t, i, m + 1, ta, pr)
          t[i] += 1; t[i + 1] += 1; t[i + 2] += 1
        end
        if t[i] >= 2
          t[i] -= 2
          walk.(t, i, m, ta, 1) if pr.zero?
          walk.(t, i, m, ta + 1, pr)
          t[i] += 2
        end
        if suit && i % 9 <= 7 && t[i + 1].positive?
          t[i] -= 1; t[i + 1] -= 1; walk.(t, i, m, ta + 1, pr); t[i] += 1; t[i + 1] += 1
        end
        if suit && i % 9 <= 6 && t[i + 2].positive?
          t[i] -= 1; t[i + 2] -= 1; walk.(t, i, m, ta + 1, pr); t[i] += 1; t[i + 2] += 1
        end
        t[i] -= 1; walk.(t, i, m, ta, pr); t[i] += 1
      end
      walk.(tiles_34.dup, 0, 0, 0, 0)
      best
    end

    it "乱数の手（副露 0〜4、打牌の前と後）で通常形の向聴数が一致する" do
      rng = Random.new(7)
      mismatches = []
      400.times do
        melds = rng.rand(0..4)
        size = (3 * (4 - melds)) + rng.rand(1..2)
        t = Array.new(34, 0)
        (0...136).to_a.shuffle(random: rng).first(size).each { |n| t[n / 4] += 1 }
        got = described_class.regular_shanten(t, melds: melds)
        want = reference(t, melds)
        mismatches << [t, melds, got, want] unless got == want
      end
      expect(mismatches).to eq([])
    end
  end
end
