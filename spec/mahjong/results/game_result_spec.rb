require_relative "../../spec_helper"

RSpec.describe Mahjong::Results::GameResult do
  let(:rule) { Mahjong::Config::RuleConfig.new }

  it "スコアから順位順の最終結果を返す" do
    results = described_class.calculate(scores: { 0 => 35_000, 1 => 28_000, 2 => 22_000, 3 => 15_000 }, rule:)

    expect(results.map(&:seat)).to eq([0, 1, 2, 3])
    expect(results.map(&:rank)).to eq([1, 2, 3, 4])
    expect(results.first.point).to eq(45.0)
  end

  it "同点時は seat 順で上位になる" do
    results = described_class.calculate(scores: { 0 => 25_000, 1 => 25_000, 2 => 20_000, 3 => 30_000 }, rule:)

    expect(results.map(&:seat)).to eq([3, 0, 1, 2])
  end
end
