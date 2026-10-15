require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Calculators::FuCalculator do
  describe ".calculate" do
    it "門前ロン平和は30符" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             agari_type: :ron, machi_type: :ryanmen, jikaze: "ton", bakaze: "ton")

      expect(described_class.calculate(ctx)).to eq(30)
    end

    it "ピンフツモは20符" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             agari_type: :tsumo, machi_type: :ryanmen, jikaze: "ton", bakaze: "ton")

      expect(described_class.calculate(ctx)).to eq(20)
    end

    it "七対子は25符" do
      form = agari_forms("1m 1m 2p 2p 3s 3s 1z 1z 2z 2z 3z 3z 4z 4z").find(&:chiitoitsu?)
      ctx = yaku_context_for("1m 1m 2p 2p 3s 3s 1z 1z 2z 2z 3z 3z 4z 4z", form:)

      expect(described_class.calculate(ctx)).to eq(25)
    end

    it "雀頭符と待ち符を加算して切り上げる" do
      ctx = yaku_context_for("1m 1m 1m 2m 3m 4m 5m 6m 7m 3p 4p 5p 5z 5z",
                             agari_type: :ron, machi_type: :tanki, bakaze: "nan")

      expect(described_class.calculate(ctx)).to eq(50)
    end

    it "連風牌雀頭はルール設定符を使う" do
      ctx = yaku_context_for("1m 1m 1m 2m 3m 4m 5m 6m 7m 3p 4p 5p 1z 1z",
                             agari_type: :ron,
                             machi_type: :tanki,
                             jikaze: "ton",
                             bakaze: "ton",
                             rule: Mahjong::Config::RuleConfig.new("renpuu_jantou_fu" => 4))

      expect(described_class.jantou_fu(ctx)).to eq(4)
    end

    it "双碰待ちのロンで完成した刻子は明刻の符で数える" do
      ctx = yaku_context_for("5z 5z 5z 2m 2m 2m 6p 7p 8p 3s 4s 5s 9p 9p",
                             agari_tile: Mahjong::Tiles::Tile.new("2m"), agari_type: :ron,
                             machi_type: :shanpon, jikaze: "sha")

      # 20 + 門前ロン 10 + 白の暗刻 8 + 2m の明刻 2 = 40
      expect(described_class.calculate(ctx)).to eq(40)
    end

    it "双碰待ちのツモで完成した刻子は暗刻の符で数える" do
      ctx = yaku_context_for("5z 5z 5z 2m 2m 2m 6p 7p 8p 3s 4s 5s 9p 9p",
                             agari_tile: Mahjong::Tiles::Tile.new("2m"), agari_type: :tsumo,
                             machi_type: :shanpon, jikaze: "sha")

      # 20 + ツモ 2 + 白の暗刻 8 + 2m の暗刻 4 = 34 → 40
      expect(described_class.calculate(ctx)).to eq(40)
    end

    it "食いピンフ形は30符" do
      chi = Mahjong::State::Fuuro.new(type: :chi, tiles: tiles("1m 2m 3m"))
      ctx = yaku_context_for("4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             agari_type: :ron, is_menzen: false, fuuros: [chi], machi_type: :ryanmen)

      expect(described_class.calculate(ctx)).to eq(30)
    end
  end
end
