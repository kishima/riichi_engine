require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Yaku::Pinfu do
  describe ".check" do
    it "門前+全順子+非役牌雀頭+両面待ちで成立する" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             agari_type: :ron, bakaze: "ton", jikaze: "ton", machi_type: :ryanmen)

      result = described_class.check(ctx)

      expect(result&.name).to eq("pinfu")
      expect(result&.han).to eq(1)
    end

    it "雀頭が役牌なら不成立" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 1z 1z",
                             agari_type: :ron, bakaze: "nan", jikaze: "ton", machi_type: :ryanmen)

      expect(described_class.check(ctx)).to be_nil
    end

    it "鳴いている場合は不成立" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             agari_type: :ron, is_menzen: false, machi_type: :ryanmen)

      expect(described_class.check(ctx)).to be_nil
    end

    it "両面待ちでない場合は不成立" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             agari_type: :ron, machi_type: :kanchan)

      expect(described_class.check(ctx)).to be_nil
    end
  end
end
