require_relative "../../spec_helper"

RSpec.describe Mahjong::State::Hand do
  let(:tile) { ->(n) { Mahjong::Tiles::Tile.new(n) } }

  describe "#add" do
    it "牌を追加した新しい Hand を返す" do
      hand = described_class.new([tile.("1m"), tile.("2m")])
      new_hand = hand.add(tile.("3m"))
      expect(new_hand.count).to eq(3)
      expect(hand.count).to eq(2)
    end
  end

  describe "#remove" do
    it "指定牌を除去した新しい Hand を返す" do
      hand = described_class.new([tile.("1m"), tile.("2m"), tile.("3m")])
      new_hand = hand.remove(tile.("2m"))
      expect(new_hand.count).to eq(2)
      expect(new_hand.include?(tile.("2m"))).to be false
    end

    it "存在しない牌を除去すると TileNotFoundError が発生する" do
      hand = described_class.new([tile.("1m")])
      expect { hand.remove(tile.("9p")) }.to raise_error(Mahjong::Errors::TileNotFoundError)
    end
  end

  describe "#to_34" do
    it "正しい34配列を返す" do
      hand = described_class.new([tile.("1m"), tile.("1m"), tile.("9p")])
      counts = hand.to_34
      expect(counts[0]).to eq(2)
      expect(counts[17]).to eq(1)
    end
  end

  describe ".from_array" do
    it "文字列配列から Hand を生成する" do
      hand = described_class.from_array(%w[1m 2m 3m])
      expect(hand.count).to eq(3)
    end
  end

  describe "#sorted" do
    it "ソートされた Hand を返す" do
      hand = described_class.new([tile.("9p"), tile.("1m"), tile.("3z")])
      sorted = hand.sorted
      expect(sorted.tiles.first.to_s).to eq("1m")
    end
  end
end
