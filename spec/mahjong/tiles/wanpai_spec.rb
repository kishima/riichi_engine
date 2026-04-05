require_relative "../../spec_helper"

RSpec.describe Mahjong::Tiles::Wanpai do
  let(:tiles_14) do
    Mahjong::Tiles::Tile.all_tiles.first(14)
  end

  describe "#initialize" do
    it "14枚でないとエラーになる" do
      expect { described_class.new(tiles_14.first(13)) }.to raise_error(Mahjong::Errors::EngineError)
    end

    it "初期状態でドラ表示牌が1枚である" do
      wanpai = described_class.new(tiles_14)
      expect(wanpai.dora_hyouji.size).to eq(1)
      expect(wanpai.uradora_hyouji.size).to eq(1)
    end
  end

  describe "#reveal_new_dora!" do
    it "ドラ表示牌が増える" do
      wanpai = described_class.new(tiles_14)
      wanpai.reveal_new_dora!
      expect(wanpai.dora_hyouji.size).to eq(2)
    end
  end

  describe "#dora_tiles" do
    it "表示牌の次の牌を返す" do
      wanpai = described_class.new(tiles_14)
      dora_hyouji = wanpai.dora_hyouji.first
      expected = Mahjong::Tiles::Tile.new(dora_hyouji.next_tile_notation)
      expect(wanpai.dora_tiles.first.same_kind?(expected)).to be true
    end
  end

  describe "#to_h / .from_hash" do
    it "シリアライズ/デシリアライズできる" do
      wanpai = described_class.new(tiles_14)
      wanpai.reveal_new_dora!
      h = wanpai.to_h
      restored = described_class.from_hash(h)

      expect(restored.dora_hyouji.map(&:to_s)).to eq(wanpai.dora_hyouji.map(&:to_s))
      expect(restored.uradora_hyouji.map(&:to_s)).to eq(wanpai.uradora_hyouji.map(&:to_s))
      expect(restored.rinshan_remaining).to eq(wanpai.rinshan_remaining)
      expect { restored.reveal_new_dora! }.not_to raise_error
    end
  end
end
