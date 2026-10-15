require_relative "../../spec_helper"

RSpec.describe Mahjong::Tiles::Wall do
  describe ".build" do
    it "136枚の壁牌を生成する" do
      wall = described_class.build
      expect(wall.remaining).to eq(136)
    end

    it "同じ seed で同じ順序が再現される" do
      wall1 = described_class.build(seed: "abc123")
      wall2 = described_class.build(seed: "abc123")
      expect(wall1.to_a).to eq(wall2.to_a)
    end

    it "異なる seed で異なる順序になる（確率的）" do
      wall1 = described_class.build(seed: "abc")
      wall2 = described_class.build(seed: "xyz")
      expect(wall1.to_a).not_to eq(wall2.to_a)
    end

    it "英数字以外を含む seed も全体で区別する" do
      wall1 = described_class.build(seed: "round-001")
      wall2 = described_class.build(seed: "round-002")
      expect(wall1.to_a).not_to eq(wall2.to_a)
      expect(described_class.build(seed: "round-001").to_a).to eq(wall1.to_a)
    end

    it "英数字だけの seed は従来と同じ順序になる" do
      expected = Mahjong::Tiles::Tile.all_tiles.shuffle(random: Random.new("abc123".to_i(36))).map(&:to_s)
      expect(described_class.build(seed: "abc123").to_a).to eq(expected)
    end
  end

  describe "#draw!" do
    it "先頭から1枚取れる" do
      wall = described_class.build(seed: "test")
      first = wall.to_a.first
      drawn = wall.draw!
      expect(drawn.to_s).to eq(first)
      expect(wall.remaining).to eq(135)
    end

    it "空になるとエラーが発生する" do
      wall = described_class.new([])
      expect { wall.draw! }.to raise_error(Mahjong::Errors::EngineError)
    end
  end

  describe "#draw_many!" do
    it "指定枚数を取れる" do
      wall = described_class.build
      tiles = wall.draw_many!(13)
      expect(tiles.size).to eq(13)
      expect(wall.remaining).to eq(123)
    end
  end
end
