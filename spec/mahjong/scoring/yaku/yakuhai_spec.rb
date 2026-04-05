require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Yaku::Yakuhai do
  describe ".check" do
    it "三元牌の刻子を判定する" do
      ctx = yaku_context_for("5z 5z 5z 2m 3m 4m 3m 4m 5m 6p 7p 8p 9s 9s",
                             agari_type: :ron, bakaze: "nan")

      result = described_class.check(ctx)

      expect(result.map(&:name)).to include("yakuhai_haku")
    end

    it "連風牌は自風と場風の両方を返す" do
      ctx = yaku_context_for("1z 1z 1z 2m 3m 4m 3m 4m 5m 6p 7p 8p 9s 9s",
                             agari_type: :ron, jikaze: "ton", bakaze: "ton")

      result = described_class.check(ctx)
      names = result.map(&:name)

      expect(names).to include("yakuhai_jikaze")
      expect(names).to include("yakuhai_bakaze")
    end

    it "役牌刻子がなければ不成立" do
      ctx = yaku_context_for("2m 2m 2m 3m 4m 5m 4m 5m 6m 6p 7p 8p 9s 9s",
                             agari_type: :ron, bakaze: "nan")

      expect(described_class.check(ctx)).to be_nil
    end
  end
end
