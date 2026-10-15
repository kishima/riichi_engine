require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Yaku::Tanyao do
  describe ".check" do
    let(:hand) { "2m 3m 4m 3m 4m 5m 4m 5m 6m 2p 3p 4p 5p 5p" }

    it "全て中張牌なら成立する" do
      ctx = yaku_context_for(hand, agari_type: :ron, machi_type: :tanki)

      result = described_class.check(ctx)

      expect(result&.name).to eq("tanyao")
      expect(result&.han).to eq(1)
    end

    it "食いタンありルールでは副露手でも成立する" do
      ctx = yaku_context_for(hand, agari_type: :ron, is_menzen: false, machi_type: :tanki)

      expect(described_class.check(ctx)&.name).to eq("tanyao")
    end

    it "食いタンなしルールでは副露手で不成立" do
      ctx = yaku_context_for(hand,
                             agari_type: :ron,
                             is_menzen: false,
                             machi_type: :tanki,
                             rule: Mahjong::Config::RuleConfig.new("kuitan" => false))

      expect(described_class.check(ctx)).to be_nil
    end

    it "赤五を含んでも成立する" do
      ctx = yaku_context_for("2m 3m 4m 3m 4m 0m 4m 5m 6m 2p 3p 4p 0p 5p", agari_type: :ron, machi_type: :tanki)

      expect(described_class.check(ctx)&.name).to eq("tanyao")
    end

    it "么九牌を含むと不成立" do
      ctx = yaku_context_for("1m 2m 3m 3m 4m 5m 4m 5m 6m 2p 3p 4p 5p 5p",
                             agari_type: :ron, machi_type: :tanki)

      expect(described_class.check(ctx)).to be_nil
    end
  end
end
