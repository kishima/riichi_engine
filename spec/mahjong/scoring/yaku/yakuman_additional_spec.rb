require_relative "../../../spec_helper"

RSpec.describe "Mahjong::Yaku additional yakuman" do
  describe Mahjong::Scoring::Yaku::Daisangen do
    it "大三元を判定する" do
      ctx = yaku_context_for("5z 5z 5z 6z 6z 6z 7z 7z 7z 1m 2m 3m 9s 9s", agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("daisangen")
    end
  end

  describe Mahjong::Scoring::Yaku::Shousuushii do
    it "小四喜を判定する" do
      ctx = yaku_context_for("1z 1z 1z 2z 2z 2z 3z 3z 3z 4z 4z 1m 2m 3m", agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("shousuushii")
    end
  end

  describe Mahjong::Scoring::Yaku::Daisuushii do
    it "大四喜を判定する" do
      ctx = yaku_context_for("1z 1z 1z 2z 2z 2z 3z 3z 3z 4z 4z 4z 5m 5m", agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("daisuushii")
    end
  end

  describe Mahjong::Scoring::Yaku::Tsuuiisou do
    it "字一色を判定する" do
      form = agari_forms("1z 1z 1z 2z 2z 2z 3z 3z 3z 4z 4z 4z 5z 5z").first
      ctx = yaku_context_for("1z 1z 1z 2z 2z 2z 3z 3z 3z 4z 4z 4z 5z 5z", form:, agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("tsuuiisou")
    end
  end

  describe Mahjong::Scoring::Yaku::Ryuuiisou do
    it "緑一色を判定する" do
      form = agari_forms("2s 2s 2s 3s 3s 3s 4s 4s 4s 6s 6s 6s 8s 8s").first
      ctx = yaku_context_for("2s 2s 2s 3s 3s 3s 4s 4s 4s 6s 6s 6s 8s 8s", form:, agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("ryuuiisou")
    end
  end

  describe Mahjong::Scoring::Yaku::Chinroutou do
    it "清老頭を判定する" do
      form = agari_forms("1m 1m 1m 9m 9m 9m 1p 1p 1p 9p 9p 9p 1s 1s").first
      ctx = yaku_context_for("1m 1m 1m 9m 9m 9m 1p 1p 1p 9p 9p 9p 1s 1s", form:, agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("chinroutou")
    end
  end

  describe Mahjong::Scoring::Yaku::ChuurenPoutou do
    it "九蓮宝燈を判定する" do
      form = agari_forms("1m 1m 1m 2m 3m 4m 5m 5m 6m 7m 8m 9m 9m 9m").first
      ctx = yaku_context_for("1m 1m 1m 2m 3m 4m 5m 5m 6m 7m 8m 9m 9m 9m", form:, agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("chuuren_poutou")
    end
  end

  describe Mahjong::Scoring::Yaku::Suukantsu do
    it "四槓子を判定する" do
      fuuros = [
        Mahjong::State::Fuuro.new(type: :ankan, tiles: tiles("1m 1m 1m 1m")),
        Mahjong::State::Fuuro.new(type: :ankan, tiles: tiles("2m 2m 2m 2m")),
        Mahjong::State::Fuuro.new(type: :ankan, tiles: tiles("3m 3m 3m 3m")),
        Mahjong::State::Fuuro.new(type: :ankan, tiles: tiles("4m 4m 4m 4m"))
      ]
      ctx = yaku_context_for("5p 5p 5p 6s 7s 8s 7z 7z 1p 2p 3p", fuuros:, agari_type: :tsumo)
      expect(described_class.check(ctx)&.name).to eq("suukantsu")
    end
  end
end
