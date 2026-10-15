require_relative "../../../spec_helper"

RSpec.describe Mahjong::Flow::Resolvers::ActionResolver do
  it "ロン > ポン > チー の優先順位で解決する" do
    pending = {
      2 => [{ type: :chi, tiles: %w[2m 3m] }],
      1 => [{ type: :pon, tiles: %w[5p 5p] }],
      3 => [{ type: :ron_agari }]
    }

    expect(described_class.resolve(pending)).to eq(type: :ron_agari, seat: 3)
  end

  it "同順位なら seat の若い順を優先する" do
    pending = {
      2 => [{ type: :pon, tiles: %w[5p 5p] }],
      1 => [{ type: :pon, tiles: %w[5p 5p] }]
    }

    expect(described_class.resolve(pending)[:seat]).to eq(1)
  end

  it "from_seat を渡すと、同順位は打牌者の下家から順に優先する（頭はね）" do
    pending = {
      0 => [{ type: :ron_agari }],
      2 => [{ type: :ron_agari }]
    }

    expect(described_class.resolve(pending, from_seat: 1)).to eq(type: :ron_agari, seat: 2)
    expect(described_class.resolve(pending, from_seat: 3)).to eq(type: :ron_agari, seat: 0)
  end

  it "from_seat を渡しても優先順位はアクションの種類が先" do
    pending = {
      3 => [{ type: :pon, tiles: %w[5p 5p] }],
      1 => [{ type: :ron_agari }]
    }

    expect(described_class.resolve(pending, from_seat: 2)).to eq(type: :ron_agari, seat: 1)
  end

  it "候補がなければ nil を返す" do
    expect(described_class.resolve({})).to be_nil
  end

  describe "rule を渡したときの複数のロン" do
    let(:two_rons) { { 1 => [{ type: :ron_agari }], 3 => [{ type: :ron_agari }, { type: :pon, tiles: %w[5p 5p] }] } }
    let(:three_rons) { { 0 => [{ type: :ron_agari }], 1 => [{ type: :ron_agari }], 3 => [{ type: :ron_agari }] } }

    it "double_ron なら 2 人とも和了るロンを返す" do
      rule = Mahjong::Config::RuleConfig.new("double_ron" => true)

      expect(described_class.resolve(two_rons, rule:)).to eq(type: :ron_agari, seat: 1, seats: [1, 3])
    end

    it "double_ron が偽なら 1 人だけ（rule を渡さないときと同じ）" do
      rule = Mahjong::Config::RuleConfig.new("double_ron" => false)

      expect(described_class.resolve(two_rons, rule:)).to eq(described_class.resolve(two_rons))
      expect(described_class.resolve(two_rons, rule:)).to eq(type: :ron_agari, seat: 1)
    end

    it "3 人のロンは triple_ron_draw なら三家和" do
      rule = Mahjong::Config::RuleConfig.new("triple_ron_draw" => true)

      expect(described_class.resolve(three_rons, rule:)).to eq(type: :sanchahou, seats: [0, 1, 3])
    end

    it "3 人のロンは triple_ron_draw が偽で double_ron なら 3 人とも和了る" do
      rule = Mahjong::Config::RuleConfig.new("triple_ron_draw" => false, "double_ron" => true)

      expect(described_class.resolve(three_rons, rule:)).to eq(type: :ron_agari, seat: 0, seats: [0, 1, 3])
    end

    it "ロンが 1 人ならほかの宣言があっても今までどおり" do
      rule = Mahjong::Config::RuleConfig.new
      pending = { 1 => [{ type: :pon, tiles: %w[5p 5p] }], 3 => [{ type: :ron_agari }] }

      expect(described_class.resolve(pending, rule:)).to eq(type: :ron_agari, seat: 3)
    end
  end
end
