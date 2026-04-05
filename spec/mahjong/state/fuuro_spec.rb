require_relative "../../spec_helper"

RSpec.describe Mahjong::State::Fuuro do
  describe "#keeps_menzen?" do
    it "暗槓のみ門前を維持する" do
      ankan = described_class.new(type: :ankan, tiles: tiles("5m 5m 5m 5m"))
      pon = described_class.new(type: :pon, tiles: tiles("5m 5m 5m"))

      expect(ankan.keeps_menzen?).to be true
      expect(pon.keeps_menzen?).to be false
    end
  end

  describe "#to_mentsu" do
    it "チーを明順子に変換する" do
      fuuro = described_class.new(type: :chi, tiles: tiles("3m 4m 5m"))
      mentsu = fuuro.to_mentsu

      expect(mentsu).to be_shuntsu
      expect(mentsu).to be_open
    end

    it "暗槓を暗槓子に変換する" do
      fuuro = described_class.new(type: :ankan, tiles: tiles("7p 7p 7p 7p"))
      mentsu = fuuro.to_mentsu

      expect(mentsu).to be_kantsu
      expect(mentsu).to be_closed
    end
  end
end
