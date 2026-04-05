require_relative "../../spec_helper"

RSpec.describe Mahjong::State::Kawa do
  describe "discard operations" do
    it "捨て牌を追加して種別判定できる" do
      kawa = described_class.new

      kawa.add("0m", tsumogiri: true, riichi: true)

      expect(kawa.count).to eq(1)
      expect(kawa.last_tile.to_s).to eq("0m")
      expect(kawa.includes_kind?(Mahjong::Tiles::Tile.new("5m"))).to be true
    end

    it "最後の牌を鳴かれた状態にできる" do
      kawa = described_class.new
      kawa.add("1m")

      kawa.mark_last_called!

      expect(kawa.to_a.last[:called]).to be true
    end
  end

  describe ".from_array" do
    it "配列から復元できる" do
      kawa = described_class.from_array([
        { tile: "1m", tsumogiri: false, riichi: false, called: false },
        { tile: "2m", tsumogiri: true, riichi: true, called: true }
      ])

      expect(kawa.count).to eq(2)
      expect(kawa.discarded_tile_kinds).to include(["m", 1], ["m", 2])
      expect(kawa.to_a.last[:called]).to be true
    end
  end
end
