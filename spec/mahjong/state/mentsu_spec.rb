require_relative "../../spec_helper"

RSpec.describe Mahjong::State::Mentsu do
  let(:tile) { ->(n) { Mahjong::Tiles::Tile.new(n) } }

  describe "#fu" do
    context "順子" do
      it "0符を返す" do
        mentsu = described_class.new(
          type: :shuntsu,
          tiles: [tile.("1m"), tile.("2m"), tile.("3m")]
        )
        expect(mentsu.fu).to eq(0)
      end
    end

    context "明刻" do
      it "中張牌は2符" do
        mentsu = described_class.new(
          type: :koutsu,
          tiles: [tile.("5m"), tile.("5m"), tile.("5m")],
          state: :open
        )
        expect(mentsu.fu).to eq(2)
      end

      it "么九牌は4符" do
        mentsu = described_class.new(
          type: :koutsu,
          tiles: [tile.("1m"), tile.("1m"), tile.("1m")],
          state: :open
        )
        expect(mentsu.fu).to eq(4)
      end
    end

    context "暗刻" do
      it "中張牌は4符" do
        mentsu = described_class.new(
          type: :koutsu,
          tiles: [tile.("5p"), tile.("5p"), tile.("5p")],
          state: :closed
        )
        expect(mentsu.fu).to eq(4)
      end

      it "么九牌は8符" do
        mentsu = described_class.new(
          type: :koutsu,
          tiles: [tile.("9s"), tile.("9s"), tile.("9s")],
          state: :closed
        )
        expect(mentsu.fu).to eq(8)
      end
    end

    context "明槓" do
      it "中張牌は8符" do
        mentsu = described_class.new(
          type: :kantsu,
          tiles: [tile.("3m"), tile.("3m"), tile.("3m"), tile.("3m")],
          state: :open
        )
        expect(mentsu.fu).to eq(8)
      end

      it "么九牌は16符" do
        mentsu = described_class.new(
          type: :kantsu,
          tiles: [tile.("1z"), tile.("1z"), tile.("1z"), tile.("1z")],
          state: :open
        )
        expect(mentsu.fu).to eq(16)
      end
    end

    context "暗槓" do
      it "中張牌は16符" do
        mentsu = described_class.new(
          type: :kantsu,
          tiles: [tile.("5s"), tile.("5s"), tile.("5s"), tile.("5s")],
          state: :closed
        )
        expect(mentsu.fu).to eq(16)
      end

      it "么九牌は32符" do
        mentsu = described_class.new(
          type: :kantsu,
          tiles: [tile.("7z"), tile.("7z"), tile.("7z"), tile.("7z")],
          state: :closed
        )
        expect(mentsu.fu).to eq(32)
      end
    end
  end

  describe "#freeze" do
    it "イミュータブルである" do
      mentsu = described_class.new(type: :shuntsu, tiles: [tile.("1m"), tile.("2m"), tile.("3m")])
      expect(mentsu).to be_frozen
    end
  end
end
