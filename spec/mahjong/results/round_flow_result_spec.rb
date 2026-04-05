require_relative "../../spec_helper"

RSpec.describe Mahjong::Results::RoundFlowResult do
  it "局終了情報を保持する" do
    state = Mahjong::State::RoundState.new
    result = described_class.new(state: state, events: [:draw], round_end: true, round_end_info: { type: :tsumo })

    expect(result.state).to eq(state)
    expect(result.events).to eq([:draw])
    expect(result.round_end?).to be true
    expect(result.round_end_info).to eq({ type: :tsumo })
  end
end
