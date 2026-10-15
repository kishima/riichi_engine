require_relative "../../../spec_helper"

RSpec.describe "Mahjong::Yaku pattern yaku" do
  describe Mahjong::Scoring::Yaku::Iipeiko do
    it "一盃口を判定する" do
      ctx = yaku_context_for("1m 2m 3m 1m 2m 3m 4p 5p 6p 7s 8s 9s 2z 2z", agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("iipeiko")
    end

    it "同じ順子 3 つは一盃口と判定する" do
      hand = "1m 2m 3m 1m 2m 3m 1m 2m 3m 7s 8s 9s 2z 2z"
      form = agari_forms(hand).find { |f| f.parsed_hand.mentsu_notations.all? { |m| m[:type] == :shuntsu } }
      ctx = yaku_context_for(hand, form:, agari_type: :ron)

      expect(described_class.check(ctx)&.name).to eq("iipeiko")
    end
  end

  describe Mahjong::Scoring::Yaku::SanshokuDoujun do
    it "三色同順を判定する" do
      ctx = yaku_context_for("1m 2m 3m 1p 2p 3p 1s 2s 3s 4m 5m 6m 2z 2z", agari_type: :ron)
      expect(described_class.check(ctx)&.han).to eq(2)
    end
  end

  describe Mahjong::Scoring::Yaku::Ikkitsuukan do
    it "一気通貫を判定する" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 2p 3p 4p 2z 2z", agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("ikkitsuukan")
    end
  end

  describe Mahjong::Scoring::Yaku::Chanta do
    it "混全帯么九を判定する" do
      ctx = yaku_context_for("1m 2m 3m 7m 8m 9m 1p 1p 1p 1z 1z 1z 9s 9s", agari_type: :ron, bakaze: "nan")
      expect(described_class.check(ctx)&.han).to eq(2)
    end
  end

  describe Mahjong::Scoring::Yaku::Chiitoitsu do
    it "七対子を判定する" do
      form = agari_forms("1m 1m 2p 2p 3s 3s 1z 1z 2z 2z 3z 3z 4z 4z").find(&:chiitoitsu?)
      ctx = yaku_context_for("1m 1m 2p 2p 3s 3s 1z 1z 2z 2z 3z 3z 4z 4z", form:)
      expect(described_class.check(ctx)&.name).to eq("chiitoitsu")
    end
  end

  describe Mahjong::Scoring::Yaku::Toitoihou do
    it "対々和を判定する" do
      ctx = yaku_context_for("1m 1m 1m 2m 2m 2m 3m 3m 3m 4p 4p 4p 5s 5s", agari_type: :ron, machi_type: :shanpon)
      expect(described_class.check(ctx)&.name).to eq("toitoihou")
    end
  end

  describe Mahjong::Scoring::Yaku::SanAnkou do
    it "三暗刻を判定する" do
      ctx = yaku_context_for("1m 1m 1m 2m 2m 2m 3m 3m 3m 4p 5p 6p 5s 5s", agari_type: :tsumo)
      expect(described_class.check(ctx)&.name).to eq("san_ankou")
    end
  end

  describe Mahjong::Scoring::Yaku::SanKantsu do
    it "三槓子を判定する" do
      fuuros = [
        Mahjong::State::Fuuro.new(type: :ankan, tiles: tiles("1m 1m 1m 1m")),
        Mahjong::State::Fuuro.new(type: :daiminkan, tiles: tiles("2p 2p 2p 2p")),
        Mahjong::State::Fuuro.new(type: :kakan, tiles: tiles("3s 3s 3s 3s"))
      ]
      ctx = yaku_context_for("4m 5m 6m 7p 8p 9p 5z 5z 5z 6z 6z", fuuros:, agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("san_kantsu")
    end
  end

  describe Mahjong::Scoring::Yaku::Honroutou do
    it "混老頭を判定する" do
      form = agari_forms("1m 1m 1m 9m 9m 9m 1p 1p 1p 1z 1z 1z 9s 9s").first
      ctx = yaku_context_for("1m 1m 1m 9m 9m 9m 1p 1p 1p 1z 1z 1z 9s 9s", form:, agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("honroutou")
    end
  end

  describe Mahjong::Scoring::Yaku::Shousangen do
    it "小三元を判定する" do
      ctx = yaku_context_for("5z 5z 5z 6z 6z 6z 7z 7z 1m 2m 3m 4p 5p 6p", agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("shousangen")
    end
  end

  describe Mahjong::Scoring::Yaku::SanshokuDoukou do
    it "三色同刻を判定する" do
      ctx = yaku_context_for("5m 5m 5m 5p 5p 5p 5s 5s 5s 1m 2m 3m 7z 7z", agari_type: :ron)
      expect(described_class.check(ctx)&.name).to eq("sanshoku_doukou")
    end
  end

  describe Mahjong::Scoring::Yaku::Junchan do
    it "純全帯么九を判定する" do
      ctx = yaku_context_for("1m 2m 3m 7m 8m 9m 1p 2p 3p 7p 8p 9p 1s 1s", agari_type: :ron)
      expect(described_class.check(ctx)&.han).to eq(3)
    end
  end

  describe Mahjong::Scoring::Yaku::Ryanpeiko do
    it "二盃口を判定する" do
      ctx = yaku_context_for("1m 2m 3m 1m 2m 3m 4m 5m 6m 4m 5m 6m 1p 1p", agari_type: :ron, machi_type: :tanki)
      expect(described_class.check(ctx)&.name).to eq("ryanpeiko")
    end

    it "同じ順子 4 つも二盃口と判定する" do
      hand = "6p 7p 8p 6p 7p 8p 6p 7p 8p 6p 7p 8p 2s 2s"
      form = agari_forms(hand).find { |f| f.parsed_hand.mentsu_notations.all? { |m| m[:type] == :shuntsu } }
      ctx = yaku_context_for(hand, form:, agari_type: :ron, machi_type: :ryanmen)

      expect(described_class.check(ctx)&.name).to eq("ryanpeiko")
      expect(Mahjong::Scoring::Yaku::Iipeiko.check(ctx)).to be_nil
    end
  end
end
