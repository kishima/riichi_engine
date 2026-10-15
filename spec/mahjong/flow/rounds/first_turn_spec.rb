require_relative "../../../spec_helper"

# 第一巡（ダブル立直・天和・地和・九種九牌）は席ごと。自分の第一打牌か、
# 誰かの鳴き（暗槓を含む）で終わる。
RSpec.describe Mahjong::Flow::Rounds::RoundFlow do
  let(:rule) { Mahjong::Config::RuleConfig.new }
  let(:snapshot) do
    Mahjong::Snapshots::GameSetupSnapshot.new(
      bakaze: "ton", kyoku: 1, honba: 0, kyoutaku: 0, oya_index: 0,
      scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
    )
  end

  # 牌山の先頭を draws にした局。手は hands で置き換える。
  def round(hands:, draws:)
    state = described_class.setup(game_snapshot: snapshot, rule:, seed: "first-turn")
    hands.each { |seat, str| state.hands[seat] = Mahjong::State::Hand.new(tiles(str)) }
    state.wall = Mahjong::Tiles::Wall.new(tiles(draws) + state.wall.tiles.drop(tiles(draws).size))
    state
  end

  def act(state, action)
    described_class.apply_action(state:, action:, rule:)
  end

  def pass_all(state)
    state.pending_actions.keys.each { |seat| act(state, { type: :skip, seat: seat }) } if state.phase == :naki_wait
  end

  let(:quiet_hands) do
    {
      0 => "1m 4m 7m 1p 4p 7p 1s 4s 7s 2z 3z 4z 6z",
      2 => "2m 5m 8m 2p 5p 8p 2s 5s 8s 1z 1z 3m 3p",
      3 => "3m 6m 9m 3p 6p 9p 3s 6s 9s 4m 4p 4s 6m"
    }
  end

  it "親の第一打牌の後も、子はまだ第一巡で九種九牌を宣言できる" do
    state = round(hands: quiet_hands.merge(1 => "1m 9m 1p 9p 1s 9s 1z 2z 3z 2m 3m 4m 5m"), draws: "7z 6p")
    act(state, { type: :tsumo })
    act(state, { type: :dahai, seat: 0, tile: "7z" })
    pass_all(state)

    expect(state.first_turn_flags).to eq(0 => false, 1 => true, 2 => true, 3 => true)
    act(state, { type: :tsumo })
    actions = described_class.available_actions(state:, seat: 1, rule:)
    expect(actions).to include({ type: :kyuushu_kyuuhai })
  end

  it "子の第一打牌のリーチはダブル立直" do
    state = round(hands: quiet_hands.merge(1 => "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s"), draws: "7z 5z")
    act(state, { type: :tsumo })
    act(state, { type: :dahai, seat: 0, tile: "7z" })
    pass_all(state)
    act(state, { type: :tsumo })
    act(state, { type: :riichi, seat: 1, tile: "5z" })

    expect(state.double_riichi_flags[1]).to be(true)
  end

  it "子の第一ツモの和了は地和" do
    state = round(hands: quiet_hands.merge(1 => "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s"), draws: "7z 3s")
    act(state, { type: :tsumo })
    act(state, { type: :dahai, seat: 0, tile: "7z" })
    pass_all(state)
    act(state, { type: :tsumo })
    act(state, { type: :tsumo_agari, seat: 1 })

    win_snapshot = Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze: "ton", oya_index: 0, honba: 0, kyoutaku: 0, jikaze: "nan")
    winner, = RiichiEngine::API.evaluate_win(state:, seat: 1, agari_type: :tsumo, agari_tile: state.last_tsumo, rule:,
                                             extra_flags: {}, snapshot: win_snapshot)
    expect(winner[:yaku].map { |y| y[:name] }).to eq(["chiihou"])
  end

  it "鳴きが入ると、まだ打牌していない席の第一巡も終わる" do
    hands = quiet_hands.merge(1 => "1m 9m 1p 9p 1s 9s 1z 2z 3z 2m 3m 4m 5m", 2 => "2m 5m 8m 2p 5p 8p 2s 5s 8s 7z 7z 3m 3p")
    state = round(hands:, draws: "7z")
    act(state, { type: :tsumo })
    act(state, { type: :dahai, seat: 0, tile: "7z" })
    (state.pending_actions.keys - [2]).each { |seat| act(state, { type: :skip, seat: seat }) }
    act(state, { type: :pon, seat: 2 })

    expect(state.first_turn_flags.values).to all(be(false))
  end

  it "暗槓でも第一巡は終わる" do
    state = round(hands: quiet_hands.merge(0 => "1m 1m 1m 4m 7m 1p 4p 7p 1s 4s 7s 2z 3z"), draws: "1m 5z")
    act(state, { type: :tsumo })
    act(state, { type: :ankan, seat: 0, tile: "1m" })

    expect(state.first_turn_flags.values).to all(be(false))
  end
end
