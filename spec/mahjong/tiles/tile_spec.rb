require_relative "../../spec_helper"

RSpec.describe Mahjong::Tiles::Tile do
  describe ".new" do
    it "萬子1を生成する" do
      tile = described_class.new("1m")
      expect(tile.suit).to eq("m")
      expect(tile.number).to eq(1)
      expect(tile.aka?).to be false
    end

    it "赤五筒を生成する" do
      tile = described_class.new("0p")
      expect(tile.suit).to eq("p")
      expect(tile.aka?).to be true
      expect(tile.effective_number).to eq(5)
    end

    it "字牌(東)を生成する" do
      tile = described_class.new("1z")
      expect(tile.suit).to eq("z")
      expect(tile.number).to eq(1)
      expect(tile.kazehai?).to be true
      expect(tile.jihai?).to be true
    end

    it "不正な表記でエラーが発生する" do
      expect { described_class.new("10m") }.to raise_error(ArgumentError)
      expect { described_class.new("0z") }.to raise_error(ArgumentError)
      expect { described_class.new("8z") }.to raise_error(ArgumentError)
      expect { described_class.new("abc") }.to raise_error(ArgumentError)
    end
  end

  describe "分類判定" do
    it "suuhai? が正しく動作する" do
      expect(described_class.new("5m").suuhai?).to be true
      expect(described_class.new("1z").suuhai?).to be false
    end

    it "yaochu? が正しく動作する" do
      expect(described_class.new("1m").yaochu?).to be true
      expect(described_class.new("9s").yaochu?).to be true
      expect(described_class.new("1z").yaochu?).to be true
      expect(described_class.new("5m").yaochu?).to be false
    end

    it "chunchan? が正しく動作する" do
      expect(described_class.new("2m").chunchan?).to be true
      expect(described_class.new("8s").chunchan?).to be true
      expect(described_class.new("1m").chunchan?).to be false
      expect(described_class.new("9p").chunchan?).to be false
      expect(described_class.new("1z").chunchan?).to be false
      expect(described_class.new("0m").chunchan?).to be true
    end

    it "sangenpai? が正しく動作する" do
      expect(described_class.new("5z").sangenpai?).to be true
      expect(described_class.new("6z").sangenpai?).to be true
      expect(described_class.new("7z").sangenpai?).to be true
      expect(described_class.new("4z").sangenpai?).to be false
    end
  end

  describe "#same_kind?" do
    it "赤を区別せず同種か判定する" do
      tile_5m = described_class.new("5m")
      tile_0m = described_class.new("0m")
      expect(tile_5m.same_kind?(tile_0m)).to be true
      expect(tile_0m.same_kind?(tile_5m)).to be true
    end

    it "異なる牌種を区別する" do
      expect(described_class.new("1m").same_kind?(described_class.new("1p"))).to be false
    end
  end

  describe "#next_tile_notation" do
    it "数牌の次の牌が正しい" do
      expect(described_class.new("1m").next_tile_notation).to eq("2m")
      expect(described_class.new("9m").next_tile_notation).to eq("1m")
      expect(described_class.new("5p").next_tile_notation).to eq("6p")
    end

    it "字牌(風牌)の次の牌が正しい" do
      expect(described_class.new("1z").next_tile_notation).to eq("2z")
      expect(described_class.new("4z").next_tile_notation).to eq("1z")
    end

    it "字牌(三元牌)の次の牌が正しい" do
      expect(described_class.new("5z").next_tile_notation).to eq("6z")
      expect(described_class.new("7z").next_tile_notation).to eq("5z")
    end
  end

  describe ".all_tiles" do
    it "136枚を生成する" do
      tiles = described_class.all_tiles
      expect(tiles.size).to eq(136)
    end

    it "赤ドラ設定に従って赤牌を含む" do
      tiles = described_class.all_tiles({ "m" => 1, "p" => 1, "s" => 1 })
      aka_tiles = tiles.select(&:aka?)
      expect(aka_tiles.size).to eq(3)
    end

    it "赤ドラなしで生成できる" do
      tiles = described_class.all_tiles({ "m" => 0, "p" => 0, "s" => 0 })
      expect(tiles.select(&:aka?).size).to eq(0)
      expect(tiles.size).to eq(136)
    end
  end

  describe "比較" do
    it "ソートできる" do
      tiles = [
        described_class.new("9p"),
        described_class.new("1m"),
        described_class.new("5z"),
        described_class.new("3s")
      ]
      sorted = tiles.sort
      expect(sorted.first.to_s).to eq("1m")
      expect(sorted.last.to_s).to eq("5z")
    end
  end

  describe "#freeze" do
    it "イミュータブルである" do
      tile = described_class.new("3m")
      expect(tile).to be_frozen
    end
  end
end
