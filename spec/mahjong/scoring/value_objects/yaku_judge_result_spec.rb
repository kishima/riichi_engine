require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::ValueObjects::YakuJudgeResult do
  it "役一覧と役満フラグを保持する" do
    entry = Mahjong::Scoring::ValueObjects::YakuEntry.new(name: "riichi", han: 1, display: "立直")
    result = described_class.new(yaku: [entry], is_yakuman: false, total_han: 1)

    expect(result.has_yaku?).to be true
    expect(result.yakuman?).to be false
    expect(result.to_a).to eq([{ name: "riichi", han: 1 }])
  end
end
