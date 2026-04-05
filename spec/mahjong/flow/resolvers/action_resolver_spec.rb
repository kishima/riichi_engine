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

  it "候補がなければ nil を返す" do
    expect(described_class.resolve({})).to be_nil
  end
end
