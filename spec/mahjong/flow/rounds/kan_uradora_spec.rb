require_relative "../../../spec_helper"

# 槓のたびに新ドラと一緒に槓裏の表示牌も増える。和了の評価（WinEvaluator）は
# RoundState#uradora_hyouji を読むので、槓裏はそこに入っていなければならない。
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

  # 王牌: 嶺上牌 5s ほか、ドラ表示牌 3z（槓ドラ 1p）、裏ドラ表示牌 9s（槓裏 1z → 2z が裏ドラ）。
  # 席 0 が 2z を暗槓し、嶺上牌の 5s で和了る形。
  def after_ankan
    state = described_class.setup(game_snapshot: snapshot, rule:, seed: "kanura")
    state.wanpai = Mahjong::Tiles::Wanpai.new(
      tiles("5s 6s 7s 8s 3z 1p 1p 1p 1p 9s 1z 9s 9s 9s")
    )
    state.dora_hyouji = state.wanpai.dora_hyouji.dup
    state.uradora_hyouji = state.wanpai.uradora_hyouji.dup
    state.hands[0] = Mahjong::State::Hand.new(tiles("2z 2z 2z 2z 1m 2m 3m 4m 5m 6m 7p 8p 9p"))
    state.wall = Mahjong::Tiles::Wall.new(tiles("5s") + state.wall.tiles.drop(1))
    act(state, { type: :tsumo })
    act(state, { type: :ankan, seat: 0, tile: "2z" })
    state
  end

  it "槓のあと槓裏の表示牌が RoundState に入る" do
    state = after_ankan

    expect(state.dora_hyouji.map(&:to_s)).to eq(%w[3z 1p])
    expect(state.uradora_hyouji.map(&:to_s)).to eq(%w[9s 1z])
  end

  it "立直の和了で槓裏を数える" do
    state = after_ankan
    state.riichi_flags[0] = true
    state.first_turn_flags[0] = false
    winner, = Mahjong::Scoring::Evaluators::WinEvaluator.evaluate(
      state:, seat: 0, agari_type: :tsumo, agari_tile: state.last_tsumo, rule:,
      extra_flags: { rinshan: true },
      snapshot: Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze: "ton", oya_index: 0, honba: 0, kyoutaku: 0, jikaze: "ton")
    )

    ura = winner[:yaku].find { |y| y[:name] == "uradora" }
    expect(ura && ura[:han]).to eq(4)
  end

  it "JSON に保存して読み戻しても槓裏が残る" do
    state = after_ankan
    back = Mahjong::State::RoundState.from_json(state.to_json)

    expect(back.uradora_hyouji.map(&:to_s)).to eq(%w[9s 1z])
  end
end
