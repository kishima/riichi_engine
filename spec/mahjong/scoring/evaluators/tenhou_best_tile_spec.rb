require_relative "../../../spec_helper"

# tenhou_best_tile（既定は偽）: 天和では、最も高い点になる牌を和了牌とする。
# 偽なら自摸った牌が和了牌（0.1.0 と同じ）。
RSpec.describe Mahjong::Scoring::Evaluators::WinEvaluator do
  let(:base) { { "double_yakuman" => true, "multiple_yakuman" => true } }
  let(:best) { Mahjong::Config::RuleConfig.new(base.merge("tenhou_best_tile" => true)) }
  let(:plain) { Mahjong::Config::RuleConfig.new(base) }

  # 親（席 0）の配牌 14 枚の自摸和了。first: 第一巡か。
  def evaluate(hand, drawn, rule, first: true)
    state = Mahjong::State::RoundState.new
    state.hands = { 0 => Mahjong::State::Hand.new(tiles(hand)), 1 => Mahjong::State::Hand.new([]),
                    2 => Mahjong::State::Hand.new([]), 3 => Mahjong::State::Hand.new([]) }
    4.times { |s| state.first_turn_flags[s] = first }
    state.oya_seat = 0
    state.bakaze = "ton"
    state.wall = Mahjong::Tiles::Wall.new(tiles("1z 1z"))
    state.dora_hyouji = []
    state.uradora_hyouji = []
    state.phase = :round_end
    snapshot = Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze: "ton", oya_index: 0, honba: 0, kyoutaku: 0, jikaze: "ton")
    described_class.evaluate(state:, seat: 0, agari_type: :tsumo, agari_tile: Mahjong::Tiles::Tile.new(drawn),
                             rule:, extra_flags: {}, snapshot:)
  end

  four_triplets = "1m 1m 1m 2p 2p 2p 3s 3s 3s 4z 4z 4z 5z 5z"

  it "既定では自摸った牌が和了牌（1m なら四暗刻、天和と合わせて役満 2 つ）" do
    winner, score = evaluate(four_triplets, "1m", plain)

    expect(winner[:agari_hai]).to eq("1m")
    expect(winner[:yaku].map { |y| y[:display] }).to contain_exactly("天和", "四暗刻")
    expect(score.total).to eq(96_000)
  end

  it "tenhou_best_tile なら雀頭の 5z を和了牌と見て四暗刻単騎（役満 3 つ）" do
    winner, score = evaluate(four_triplets, "1m", best)

    expect(winner[:agari_hai]).to eq("5z")
    expect(winner[:yaku].map { |y| y[:display] }).to contain_exactly("天和", "四暗刻単騎")
    expect(score.total).to eq(144_000)
  end

  it "九蓮宝燈の形は純正九蓮宝燈になる" do
    winner, = evaluate("1m 1m 1m 2m 3m 4m 5m 6m 7m 8m 9m 9m 9m 9m", "1m", best)

    expect(winner[:yaku].map { |y| y[:display] }).to include("純正九蓮宝燈")
  end

  it "どの牌でも同じ点なら自摸った牌のまま" do
    winner, = evaluate("1m 2m 3m 4p 5p 6p 7s 8s 9s 2m 3m 4m 9p 9p", "3m", best)

    expect(winner[:agari_hai]).to eq("3m")
  end

  it "天和でなければ自摸った牌" do
    winner, = evaluate(four_triplets, "1m", best, first: false)

    expect(winner[:agari_hai]).to eq("1m")
    expect(winner[:yaku].map { |y| y[:display] }).to eq(["四暗刻"])
  end
end
