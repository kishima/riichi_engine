require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Yaku::Chinitsu do
  describe ".check" do
    let(:hand) { "1m 2m 3m 4m 5m 6m 7m 8m 9m 1m 2m 3m 4m 4m" }

    it "門前では6翻" do
      ctx = yaku_context_for(hand, agari_type: :ron)

      result = described_class.check(ctx)

      expect(result&.name).to eq("chinitsu")
      expect(result&.han).to eq(6)
    end

    it "副露手では5翻" do
      ctx = yaku_context_for(hand, agari_type: :ron, is_menzen: false)

      expect(described_class.check(ctx)&.han).to eq(5)
    end

    it "字牌を含むと不成立" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1m 2m 3m 1z 1z",
                             agari_type: :ron)

      expect(described_class.check(ctx)).to be_nil
    end
  end
end
