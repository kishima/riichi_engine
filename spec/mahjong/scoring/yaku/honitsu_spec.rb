require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Yaku::Honitsu do
  describe ".check" do
    let(:hand) { "1m 2m 3m 4m 5m 6m 7m 8m 9m 1z 1z 2z 2z 2z" }

    it "門前では3翻" do
      ctx = yaku_context_for(hand, agari_type: :ron)

      result = described_class.check(ctx)

      expect(result&.name).to eq("honitsu")
      expect(result&.han).to eq(3)
    end

    it "副露手では2翻" do
      ctx = yaku_context_for(hand, agari_type: :ron, is_menzen: false)

      expect(described_class.check(ctx)&.han).to eq(2)
    end

    it "字牌を含まなければ不成立" do
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1m 2m 3m 4m 4m",
                             agari_type: :ron)

      expect(described_class.check(ctx)).to be_nil
    end
  end
end
