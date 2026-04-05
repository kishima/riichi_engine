require_relative "../../../spec_helper"

RSpec.describe "Mahjong::Yaku yakuman modules" do
  describe Mahjong::Scoring::Yaku::Tenhou do
    it "親の第一ツモで成立する" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             is_first_turn: true, agari_type: :tsumo, jikaze: "ton")

      expect(described_class.check(ctx)&.name).to eq("tenhou")
    end

    it "ロンでは不成立" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             is_first_turn: true, agari_type: :ron, jikaze: "ton")

      expect(described_class.check(ctx)).to be_nil
    end
  end

  describe Mahjong::Scoring::Yaku::Chiihou do
    it "子の第一ツモで成立する" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             is_first_turn: true, agari_type: :tsumo, jikaze: "nan")

      expect(described_class.check(ctx)&.name).to eq("chiihou")
    end

    it "親では不成立" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             is_first_turn: true, agari_type: :tsumo, jikaze: "ton")

      expect(described_class.check(ctx)).to be_nil
    end
  end

  describe Mahjong::Scoring::Yaku::KokushiMusou do
    it "国士無双形を判定する" do
      form = agari_forms("1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z 1m").find(&:kokushi?)
      ctx = yaku_context_for("1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z 1m", form: form)

      expect(described_class.check(ctx)&.name).to eq("kokushi_musou")
    end
  end

  describe Mahjong::Scoring::Yaku::Suuankou do
    it "門前四暗刻で成立する" do
      ctx = yaku_context_for("1m 1m 1m 2m 2m 2m 3m 3m 3m 4p 4p 4p 5s 5s",
                             agari_type: :tsumo, machi_type: :tanki)

      expect(described_class.check(ctx)&.name).to eq("suuankou")
    end

    it "シャンポン待ちロンでは不成立" do
      ctx = yaku_context_for("1m 1m 1m 2m 2m 2m 3m 3m 3m 4p 4p 4p 5s 5s",
                             agari_type: :ron, machi_type: :shanpon)

      expect(described_class.check(ctx)).to be_nil
    end
  end
end
