require_relative "../../../spec_helper"

# 槓の新ドラ。既定は槓の直後（0.1.0 と同じ）。minkan_dora_after_discard なら、明槓
# （大明槓・加槓）の新ドラはその後の打牌のとき（またはその前の次の槓のとき）にめくる。
RSpec.describe Mahjong::Flow::Rounds::RoundFlow do
  let(:late) { Mahjong::Config::RuleConfig.new("minkan_dora_after_discard" => true) }
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

  # 席 0 が 9s を切り、席 1 が 9s を大明槓する（席 1 は 2z も 4 枚持つ）。
  def after_daiminkan(rule)
    state = described_class.setup(game_snapshot: snapshot, rule:, seed: "kan-dora")
    state.hands[0] = Mahjong::State::Hand.new(tiles("1m 4m 7m 1p 4p 7p 1s 4s 7s 1z 3z 5z 6z"))
    state.hands[1] = Mahjong::State::Hand.new(tiles("9s 9s 9s 2z 2z 2z 2z 2m 5m 8m 2p 5p 8p"))
    state.hands[2] = Mahjong::State::Hand.new(tiles("3m 6m 9m 3p 6p 9p 3s 6s 1z 3z 6z 7z 4z"))
    state.hands[3] = Mahjong::State::Hand.new(tiles("1m 5m 9m 1p 5p 9p 1s 5s 1z 4z 6z 7z 3z"))
    state.wall = Mahjong::Tiles::Wall.new(tiles("9s") + state.wall.tiles.drop(1))
    act(state, { type: :tsumo }, rule)
    act(state, { type: :dahai, seat: 0, tile: "9s" }, rule)
    (state.pending_actions.keys - [1]).each { |seat| act(state, { type: :skip, seat: }, rule) }
    act(state, { type: :daiminkan, seat: 1 }, rule)
    state
  end

  it "既定のルールでは大明槓の直後にめくる" do
    state = after_daiminkan(default_rule)

    expect(state.dora_hyouji.size).to eq(2)
  end

  it "minkan_dora_after_discard なら大明槓の新ドラは打牌のときにめくる" do
    state = after_daiminkan(late)
    expect(state.dora_hyouji.size).to eq(1)
    expect(state.pending_kan_dora).to eq(1)

    discard = state.last_tsumo.to_s == "2z" ? "8p" : state.last_tsumo.to_s
    act(state, { type: :dahai, seat: 1, tile: discard }, late)

    expect(state.dora_hyouji.size).to eq(2)
    expect(state.pending_kan_dora).to eq(0)
  end

  it "打牌の前に次の槓（暗槓）をすれば、残っていた新ドラと暗槓の新ドラをめくる" do
    state = after_daiminkan(late)
    act(state, { type: :ankan, seat: 1, tile: "2z" }, late)

    expect(state.dora_hyouji.size).to eq(3)
    expect(state.pending_kan_dora).to eq(0)
  end

  it "暗槓の新ドラは minkan_dora_after_discard でも直後にめくる" do
    state = described_class.setup(game_snapshot: snapshot, rule: late, seed: "kan-dora")
    state.hands[0] = Mahjong::State::Hand.new(tiles("1m 1m 1m 4m 7m 1p 4p 7p 1s 4s 7s 2z 3z"))
    state.wall = Mahjong::Tiles::Wall.new(tiles("1m") + state.wall.tiles.drop(1))
    act(state, { type: :tsumo }, late)
    act(state, { type: :ankan, seat: 0, tile: "1m" }, late)

    expect(state.dora_hyouji.size).to eq(2)
  end

  it "加槓の新ドラも打牌のときにめくる" do
    state = described_class.setup(game_snapshot: snapshot, rule: late, seed: "kan-dora")
    pon = Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5z 5z 5z"), called_tile: Mahjong::Tiles::Tile.new("5z"), from_seat: 2)
    state.fuuros[0] = [pon]
    state.hands[0] = Mahjong::State::Hand.new(tiles("1m 4m 7m 1p 4p 7p 1s 4s 7s 2z"))
    state.wall = Mahjong::Tiles::Wall.new(tiles("5z") + state.wall.tiles.drop(1))
    act(state, { type: :tsumo }, late)
    act(state, { type: :kakan, seat: 0, tile: "5z" }, late)
    expect(state.dora_hyouji.size).to eq(1)

    act(state, { type: :dahai, seat: 0, tile: "2z" }, late)
    expect(state.dora_hyouji.size).to eq(2)
  end

  it "まだめくっていない新ドラの数は RoundState の JSON に残る" do
    state = after_daiminkan(late)

    expect(RiichiEngine::API.deserialize_round_state(state.to_json).pending_kan_dora).to eq(1)
  end
end
