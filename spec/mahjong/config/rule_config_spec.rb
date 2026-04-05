require_relative "../../spec_helper"

RSpec.describe Mahjong::Config::RuleConfig do
  describe "#initialize" do
    it "デフォルト値が設定される" do
      config = described_class.new
      expect(config.initial_score).to eq(25000)
      expect(config.kuitan).to be true
      expect(config.double_yakuman).to be false
    end

    it "カスタム設定でデフォルトを上書きできる" do
      config = described_class.new("kuitan" => false, "initial_score" => 30000)
      expect(config.kuitan).to be false
      expect(config.initial_score).to eq(30000)
      expect(config.atozuke).to be true
    end
  end

  describe "#aka_dora_config" do
    it "赤ドラ設定を返す" do
      config = described_class.new
      expect(config.aka_dora_config).to eq({ "m" => 1, "p" => 1, "s" => 1 })
    end
  end

  describe "#to_h" do
    it "設定のハッシュを返す" do
      config = described_class.new
      h = config.to_h
      expect(h).to be_a(Hash)
      expect(h["initial_score"]).to eq(25000)
    end
  end
end
