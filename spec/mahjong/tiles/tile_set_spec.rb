require_relative "../../spec_helper"

RSpec.describe Mahjong::Tiles::TileSet do
  let(:tile) { ->(n) { Mahjong::Tiles::Tile.new(n) } }

  describe ".to_34" do
    it "正しい34配列を返す" do
      tiles = [tile.("1m"), tile.("1m"), tile.("9p"), tile.("7z")]
      counts = described_class.to_34(tiles)
      expect(counts[0]).to eq(2)
      expect(counts[17]).to eq(1)
      expect(counts[33]).to eq(1)
      expect(counts.sum).to eq(4)
    end
  end

  describe ".tile_index / .from_index" do
    it "往復変換できる" do
      %w[1m 9m 1p 9p 1s 9s 1z 7z].each do |notation|
        t = tile.(notation)
        idx = described_class.tile_index(t)
        back = described_class.from_index(idx)
        expect(back).to eq(notation)
      end
    end
  end

  describe ".remove_one" do
    it "指定牌を1枚除去する" do
      tiles = [tile.("1m"), tile.("2m"), tile.("1m")]
      result = described_class.remove_one(tiles, tile.("1m"))
      expect(result.size).to eq(2)
      expect(result.count { |t| t.same_kind?(tile.("1m")) }).to eq(1)
    end
  end

  describe ".yaochu_kind_count" do
    it "么九牌の種類数を返す" do
      tiles = [tile.("1m"), tile.("9m"), tile.("1z"), tile.("1z"), tile.("5m")]
      expect(described_class.yaochu_kind_count(tiles)).to eq(3)
    end
  end
end
