require_relative "../../../spec_helper"

# 国士無双の暗槓の搶槓。既定（kokushi_ankan_chankan: false）では暗槓にロンは無い（0.1.0 と同じ）。
# 真なら、暗槓した牌で国士無双を和了れる席にロンが出る。国士無双でない待ちには出ない。
RSpec.describe Mahjong::Flow::Rounds::RoundFlow do
  let(:allowed) { Mahjong::Config::RuleConfig.new("kokushi_ankan_chankan" => true) }
  let(:default_rule) { Mahjong::Config::RuleConfig.new }
  let(:snapshot) do
    Mahjong::Snapshots::GameSetupSnapshot.new(
      bakaze: "ton", kyoku: 1, honba: 0, kyoutaku: 0, oya_index: 0,
      scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
    )
  end

  def act(state, action, rule)
    described_class.apply_action(state:, action:, rule:)
  end

  # 席 0 が 1z を暗槓する。席 1 は 1z 待ちの国士無双、席 2 は 1z 単騎のふつうの手。
  def after_ankan(rule)
    state = described_class.setup(game_snapshot: snapshot, rule:, seed: "kokushi-ankan")
    state.hands[0] = Mahjong::State::Hand.new(tiles("1z 1z 1z 2m 3m 4m 5p 6p 7p 2s 3s 4s 8p"))
    state.hands[1] = Mahjong::State::Hand.new(tiles("1m 9m 9m 1p 9p 1s 9s 2z 3z 4z 5z 6z 7z"))
    state.hands[2] = Mahjong::State::Hand.new(tiles("2m 3m 4m 5m 6m 7m 2p 3p 4p 6s 7s 8s 1z"))
    state.wall = Mahjong::Tiles::Wall.new(tiles("1z") + state.wall.tiles.drop(1))
    act(state, { type: :tsumo }, rule)
    act(state, { type: :ankan, seat: 0, tile: "1z" }, rule)
    state
  end

  it "既定のルールでは暗槓にロンは無い" do
    state = after_ankan(default_rule)

    expect(state.phase).to eq(:dahai)
    expect(state.fuuros[0].last.type).to eq(:ankan)
    expect(state.dora_hyouji.size).to eq(2)
  end

  it "国士無双の席にだけロンが出て、ロンすると暗槓した席の放銃になる" do
    state = after_ankan(allowed)
    expect(state.phase).to eq(:naki_wait)
    expect(state.pending_actions.keys).to eq([1])
    expect(described_class.available_actions(state:, seat: 1, rule: allowed).map { |a| a[:type] }).to eq(%i[ron_agari skip])

    result = act(state, { type: :ron_agari, seat: 1 }, allowed)
    expect(result.round_end_info[:loser_seat]).to eq(0)
    expect(result.round_end_info[:chankan]).to be(true)

    winner, = Mahjong::Scoring::Evaluators::WinEvaluator.evaluate(
      state:, seat: 1, agari_type: :ron, agari_tile: state.chankan_tile, rule: allowed, extra_flags: { chankan: true },
      snapshot: Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze: "ton", oya_index: 0, honba: 0, kyoutaku: 0, jikaze: "nan")
    )
    expect(winner[:yaku].map { |y| y[:name] }).to include("kokushi_musou")
  end

  it "見逃せば暗槓を終え（新ドラは暗槓なのですぐ）、見逃した席は同巡フリテン" do
    state = after_ankan(allowed)
    act(state, { type: :skip, seat: 1 }, allowed)

    expect(state.phase).to eq(:dahai)
    expect(state.current_seat).to eq(0)
    expect(state.fuuros[0].last.type).to eq(:ankan)
    expect(state.dora_hyouji.size).to eq(2)
    expect(state.chankan_tile).to be_nil
    expect(state.hands[0].tiles.size).to eq(11)
    expect(state.dojun_furiten_flags[1]).to be(true)
  end
end
