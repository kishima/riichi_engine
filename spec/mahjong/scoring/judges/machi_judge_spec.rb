require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Judges::MachiJudge do
  def t34(*notations)
    tiles = notations.map { |n| Mahjong::Tiles::Tile.new(n) }
    Mahjong::Tiles::TileSet.to_34(tiles)
  end

  def tile_idx(notation)
    Mahjong::Tiles::TileSet.tile_index(Mahjong::Tiles::Tile.new(notation))
  end

  describe ".tenpai?" do
    it "テンパイ形で true を返す" do
      # 123m 456m 789m 12p 11z → 3p 待ち
      tiles = t34("1m","2m","3m","4m","5m","6m","7m","8m","9m","1p","2p","1z","1z")
      expect(described_class.tenpai?(tiles)).to be true
    end

    it "ノーテンで false を返す" do
      tiles = t34("1m","3m","5m","7m","9m","1p","3p","5p","7p","9p","1z","3z","5z")
      expect(described_class.tenpai?(tiles)).to be false
    end
  end

  describe ".machi_tile_indices" do
    it "両面待ち: 23m → 1m と 4m" do
      # 456m 789m 123p 11z + 23m (両面待ち)
      tiles = t34("2m","3m","4m","5m","6m","7m","8m","9m","1p","2p","3p","1z","1z")
      indices = described_class.machi_tile_indices(tiles)
      expect(indices).to include(tile_idx("1m"))
      expect(indices).to include(tile_idx("4m"))
    end

    it "辺張待ち: 12m → 3m のみ" do
      # 456m 789m 123p 11z + 12m (辺張)
      tiles = t34("1m","2m","4m","5m","6m","7m","8m","9m","1p","2p","3p","1z","1z")
      indices = described_class.machi_tile_indices(tiles)
      expect(indices).to include(tile_idx("3m"))
      expect(indices).not_to include(tile_idx("0m"))
    end

    it "辺張待ち: 89m → 7m のみ" do
      tiles = t34("8m","9m","4m","5m","6m","7m","8m","9m","1p","2p","3p","1z","1z")
      # 678m 789m 123p 11z + 89m
      tiles2 = t34("8m","9m","1p","2p","3p","4p","5p","6p","7p","8p","9p","1z","1z")
      indices = described_class.machi_tile_indices(tiles2)
      expect(indices).to include(tile_idx("7m"))
      expect(indices).not_to include(tile_idx("1m"))
    end

    it "嵌張待ち: 13m → 2m のみ" do
      tiles = t34("1m","3m","4m","5m","6m","7m","8m","9m","1p","2p","3p","1z","1z")
      indices = described_class.machi_tile_indices(tiles)
      expect(indices).to include(tile_idx("2m"))
      expect(indices).not_to include(tile_idx("1m"))
    end

    it "単騎待ち: 雀頭なし + 1枚孤立 → その牌" do
      # 123m 456m 789m 123p + 1z (単騎)
      tiles = t34("1m","2m","3m","4m","5m","6m","7m","8m","9m","1p","2p","3p","1z")
      indices = described_class.machi_tile_indices(tiles)
      expect(indices).to include(tile_idx("1z"))
    end

    it "双碰待ち: 2種の対子" do
      # 123m 456m 789m + 11z 22z (双碰)
      tiles = t34("1m","2m","3m","4m","5m","6m","7m","8m","9m","1z","1z","2z","2z")
      indices = described_class.machi_tile_indices(tiles)
      expect(indices).to include(tile_idx("1z"))
      expect(indices).to include(tile_idx("2z"))
    end

    it "国士13面待ち" do
      # 么九牌13種 + 1m (東を重複させた13面待ち)
      tiles = t34("1m","9m","1p","9p","1s","9s","1z","2z","3z","4z","5z","6z","7z")
      indices = described_class.machi_tile_indices(tiles)
      expect(indices.size).to eq(13)
    end
  end

  describe ".find_machi" do
    it "MachiResult を返す" do
      tiles = t34("1m","2m","3m","4m","5m","6m","7m","8m","9m","1p","2p","3p","1z")
      results = described_class.find_machi(tiles)
      expect(results).not_to be_empty
      expect(results.first).to be_a(Mahjong::Scoring::Judges::MachiJudge::MachiResult)
    end

    it "両面待ちで machi_type が :ryanmen" do
      # 234m 567m 123p 11z + 89m (両面)
      tiles = t34("2m","3m","4m","5m","6m","7m","8m","9m","1p","2p","3p","1z","1z")
      results = described_class.find_machi(tiles)
      ryanmen_results = results.select { |r| r.machi_type == :ryanmen }
      expect(ryanmen_results).not_to be_empty
    end

    it "同じ和了形で和了牌が雀頭にも順子にも入るときは両方の待ちを返す" do
      # 123p 456p 789s 345m 5m: 5m は単騎（雀頭 55m）でも 34m の両面でもある
      tiles = t34("1p","2p","3p","4p","5p","6p","7s","8s","9s","3m","4m","5m","5m")
      results = described_class.find_machi(tiles).select { |r| r.tile_index == tile_idx("5m") }
      expect(results.map(&:machi_type)).to include(:tanki, :ryanmen)
    end
  end
end
