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
end
