require_relative "../../spec_helper"

RSpec.describe Mahjong::Tiles::Dora do
  let(:tile) { ->(n) { Mahjong::Tiles::Tile.new(n) } }

  describe ".count" do
    it "手牌中のドラ枚数を正しくカウントする" do
      all_tiles = [tile.("1m"), tile.("1m"), tile.("3p"), tile.("5m")]
      dora_tiles = [tile.("1m")]
      expect(described_class.count(all_tiles, dora_tiles)).to eq(2)
    end

    it "ドラがない場合は0を返す" do
      all_tiles = [tile.("2m"), tile.("3m")]
      dora_tiles = [tile.("9p")]
      expect(described_class.count(all_tiles, dora_tiles)).to eq(0)
    end
  end

  describe ".aka_count" do
    it "赤ドラの枚数を正しくカウントする" do
      all_tiles = [tile.("0m"), tile.("5m"), tile.("0p")]
      expect(described_class.aka_count(all_tiles)).to eq(2)
    end
  end

  describe ".uradora_count" do
    it "裏ドラの枚数を正しくカウントする" do
      all_tiles = [tile.("4m"), tile.("4m"), tile.("9s")]
      uradora_tiles = [tile.("4m")]
      expect(described_class.uradora_count(all_tiles, uradora_tiles)).to eq(2)
    end
  end
end
