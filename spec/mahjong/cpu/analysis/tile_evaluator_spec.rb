require_relative "../../../spec_helper"

RSpec.describe Mahjong::Cpu::Analysis::TileEvaluator do
  describe ".build_remaining_counts" do
    it "見えている牌を残枚数から引く" do
      counts = described_class.build_remaining_counts(tiles("1m 1m 5z"))

      expect(counts[Mahjong::Tiles::TileSet.tile_index(Mahjong::Tiles::Tile.new("1m"))]).to eq(2)
      expect(counts[Mahjong::Tiles::TileSet.tile_index(Mahjong::Tiles::Tile.new("5z"))]).to eq(3)
    end
  end

  describe ".evaluate_all_discards" do
    it "各打牌候補の向聴数と受入を返す" do
      hand = Mahjong::State::Hand.new(tiles("1m 2m 3m 4m 5m 6m 1p 2p 3p 1s 2s 3s 6z 7z"))

      result = described_class.evaluate_all_discards(hand)

      expect(result.keys).to include("6z", "7z")
      expect(result["6z"]).to be_a(Mahjong::Cpu::Analysis::EvalResult)
      expect(result["6z"].shanten).to be <= result["1m"].shanten
    end

    it "見えている牌を受入計算に反映する" do
      hand = Mahjong::State::Hand.new(tiles("1m 2m 3m 4m 5m 6m 1p 2p 3p 1s 2s 3s 6z 7z"))

      base = described_class.evaluate_all_discards(hand)
      blocked = described_class.evaluate_all_discards(hand, visible_tiles: tiles("6z 6z 6z"))

      expect(blocked["7z"].ukeire).to be <= base["7z"].ukeire
    end

    it "melds: を渡すと副露を面子として向聴数と受入を数える" do
      # 副露 1 つ: 2m3m 789m 6p7p7p 678s。6p 切りはテンパイ（23m の両面）、7p 切りは 1 向聴。
      hand = Mahjong::State::Hand.new(tiles("2m 3m 7m 8m 9m 6p 7p 7p 6s 7s 8s"))

      result = described_class.evaluate_all_discards(hand, melds: 1)

      expect(result["6p"].shanten).to eq(0)
      expect(result["7p"].shanten).to eq(1)
      expect(result["6p"].ukeire).to eq(8) # 1m と 4m
    end
  end
end
