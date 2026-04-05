require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::ValueObjects::YakuEntry do
  it "name/han/display を保持する" do
    entry = described_class.new(name: "riichi", han: 1, display: "立直")

    expect(entry.name).to eq("riichi")
    expect(entry.han).to eq(1)
    expect(entry.display).to eq("立直")
  end
end
