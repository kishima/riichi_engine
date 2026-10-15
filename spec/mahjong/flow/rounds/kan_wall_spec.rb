require_relative "../../../spec_helper"

# 槓のたびに嶺上牌を王牌から取り、牌山の最後の牌が王牌に回る（王牌は 14 枚のまま）。
RSpec.describe Mahjong::Flow::Rounds::RoundFlow do
  let(:rule) { Mahjong::Config::RuleConfig.new }
  let(:snapshot) do
    Mahjong::Snapshots::GameSetupSnapshot.new(
      bakaze: "ton", kyoku: 1, honba: 0, kyoutaku: 0, oya_index: 0,
      scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
    )
  end

  def act(state, action)
    described_class.apply_action(state:, action:, rule:)
  end

  def kan_ready_round
    state = described_class.setup(game_snapshot: snapshot, rule:, seed: "kan-wall")
    state.hands[0] = Mahjong::State::Hand.new(tiles("1m 1m 1m 4m 7m 1p 4p 7p 1s 4s 7s 2z 3z"))
    state.wall = Mahjong::Tiles::Wall.new(tiles("1m") + state.wall.tiles.drop(1))
    act(state, { type: :tsumo })
    state
  end

  it "暗槓すると牌山が 1 枚短くなり、最後の牌が無くなる" do
    state = kan_ready_round
    before = state.wall.tiles.map(&:to_s)

    act(state, { type: :ankan, seat: 0, tile: "1m" })

    expect(state.wall.remaining).to eq(before.size - 1)
    expect(state.wall.tiles.map(&:to_s)).to eq(before[0...-1])
    expect(state.wanpai.rinshan_remaining).to eq(3)
  end

  it "海底牌を引いた後は暗槓も加槓もできない" do
    state = kan_ready_round
    state.wall = Mahjong::Tiles::Wall.new([])

    expect(described_class.ankan_candidates(state, 0, rule)).to eq([])
    actions = described_class.available_actions(state:, seat: 0, rule:)
    expect(actions.map { |a| a[:type] }).not_to include(:ankan, :kakan)
  end
end
