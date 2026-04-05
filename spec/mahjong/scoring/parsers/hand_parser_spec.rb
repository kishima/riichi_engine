require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Parsers::HandParser do
  # 文字列配列から tiles_34 を生成するヘルパー
  def t34(*notations)
    tiles = notations.map { |n| Mahjong::Tiles::Tile.new(n) }
    Mahjong::Tiles::TileSet.to_34(tiles)
  end

  describe ".parse" do
    it "単純な4メンツ1雀頭で1パターンを返す" do
      # 123m 456m 789m 123p + 11z (雀頭)
      tiles_34 = t34(
        "1m","2m","3m","4m","5m","6m","7m","8m","9m",
        "1p","2p","3p",
        "1z","1z"
      )
      results = described_class.parse(tiles_34)
      expect(results).not_to be_empty
      expect(results.first).to be_a(Mahjong::Scoring::Parsers::ParsedHand)
    end

    it "和了形でない手牌で空配列を返す" do
      tiles_34 = t34("1m","2m","4m","6m","8m","1p","3p","5p","7p","9p","1z","3z","5z","7z")
      expect(described_class.parse(tiles_34)).to be_empty
    end

    it "複数の分解パターンを列挙する（三色同順系）" do
      # 1m1m1m 2m2m2m 3m3m3m + 11m (雀頭) → 刻子×3 or 順子×3
      tiles_34 = t34(
        "1m","1m","1m",
        "2m","2m","2m",
        "3m","3m","3m",
        "1z","1z",
        "2z","2z","2z"
      )
      results = described_class.parse(tiles_34)
      expect(results.size).to be >= 2
    end

    it "ParsedHand が jantou_notation を返す" do
      tiles_34 = t34(
        "1m","2m","3m","4m","5m","6m","7m","8m","9m",
        "1p","2p","3p",
        "1z","1z"
      )
      result = described_class.parse(tiles_34).first
      expect(result.jantou_notation).to eq("1z")
    end

    it "ParsedHand が mentsu_notations を返す" do
      tiles_34 = t34(
        "1m","2m","3m","4m","5m","6m","7m","8m","9m",
        "1p","2p","3p",
        "1z","1z"
      )
      result = described_class.parse(tiles_34).first
      notations = result.mentsu_notations
      expect(notations.size).to eq(4)
      types = notations.map { |m| m[:type] }
      expect(types).to all(eq(:shuntsu))
    end
  end
end
