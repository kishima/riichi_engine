require_relative "../../../spec_helper"

# リーチの宣言牌へのロン。既定（riichi_void_on_ron: false）では宣言の時点で 1000 点が供託に入ったまま
# （0.1.0 と同じ）。riichi_void_on_ron: true なら、宣言牌がロンされたリーチは成り立たず、1000 点は戻る。
# 宣言牌がロンされずに通れば（鳴かれても）リーチは成り立つ。
RSpec.describe Mahjong::Flow::Rounds::RoundFlow do
  let(:void_rule) { Mahjong::Config::RuleConfig.new("riichi_void_on_ron" => true) }
  let(:default_rule) { Mahjong::Config::RuleConfig.new }

  def snapshot(kyoutaku)
    Mahjong::Snapshots::GameSetupSnapshot.new(
      bakaze: "ton", kyoku: 1, honba: 0, kyoutaku: kyoutaku, oya_index: 0,
      scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
    )
  end

  # 席 2 が 8s を切ってリーチを宣言する手番。ron_seats の席は 8s でロンできる（断么九、6s7s の両面待ち）。
  # 席 3 は 8s をチーできる（6s7s）。
  def declaring(rule, ron_seats, kyoutaku: 0)
    state = described_class.setup(game_snapshot: snapshot(kyoutaku), rule:, seed: "riichi-declaration-ron")
    state.phase = :dahai
    state.current_seat = 2
    4.times { |seat| state.first_turn_flags[seat] = false }
    state.hands[2] = Mahjong::State::Hand.new(tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 1z 1z 5m 6m 8s"))
    pairs = { 0 => "2p 2p", 1 => "4p 4p", 3 => "3p 3p" }
    [0, 1, 3].each do |seat|
      hand = ron_seats.include?(seat) ? "2m 3m 4m 5p 6p 7p 3s 4s 5s 6s 7s #{pairs[seat]}" : "1m 1m 9m 9m 1p 9p 1z 2z 3z 4z 5z 6z 7z"
      state.hands[seat] = Mahjong::State::Hand.new(tiles(hand))
    end
    state.hands[3] = Mahjong::State::Hand.new(tiles("1m 1m 9m 9m 1p 9p 1z 2z 3z 4z 5z 6s 7s")) unless ron_seats.include?(3)
    described_class.apply_action(state:, action: { type: :riichi, seat: 2, tile: "8s" }, rule:)
    state
  end

  def ron(state, rule)
    action = RiichiEngine::API.resolve_pending_action(state.pending_actions, rule:)
    (state.pending_actions.keys - Array(action[:seats] || action[:seat])).each do |seat|
      described_class.apply_action(state:, action: { type: :skip, seat: }, rule:)
    end
    described_class.apply_action(state:, action:, rule:)
  end

  def win(state, seat, kyoutaku)
    snap = Mahjong::Snapshots::WinEvaluationSnapshot.new(
      bakaze: "ton", oya_index: 0, honba: 0, kyoutaku:, jikaze: %w[ton nan sha pei][seat]
    )
    RiichiEngine::API.evaluate_win(state:, seat:, agari_type: :ron, agari_tile: state.last_dahai[:tile],
                                   rule: void_rule, extra_flags: {}, snapshot: snap)
  end

  it "宣言のときは、どちらのルールでも 1000 点を払い供託に入れる" do
    [default_rule, void_rule].each do |rule|
      state = declaring(rule, [0])

      expect(state.scores[2]).to eq(24_000)
      expect(state.kyoutaku).to eq(1)
      expect(state.riichi_flags[2]).to be(true)
    end
  end

  it "既定のルールでは、宣言牌がロンされても 1000 点は供託のまま" do
    state = declaring(default_rule, [0])
    result = ron(state, default_rule)

    expect(result.round_end_info[:winners]).to eq([{ seat: 0 }])
    expect(state.scores[2]).to eq(24_000)
    expect(state.kyoutaku).to eq(1)
    expect(state.riichi_flags[2]).to be(true)
  end

  it "riichi_void_on_ron なら、宣言牌へのロンでリーチは成り立たず、1000 点が戻る" do
    state = declaring(void_rule, [0])
    result = ron(state, void_rule)

    expect(result.round_end_info[:winners]).to eq([{ seat: 0 }])
    expect(state.scores[2]).to eq(25_000)
    expect(state.kyoutaku).to eq(0)
    expect(state.riichi_flags[2]).to be(false)
    expect(state.ippatsu_flags[2]).to be(false)
    expect(state.kawas[2].tiles.last.riichi).to be(true)
    _winner, score = win(state, 0, state.kyoutaku)
    expect(score.kyoutaku_bonus).to eq(0)
  end

  it "ダブロンでも 1000 点は 1 度だけ戻り、前からの供託はそのまま和了者へ" do
    state = declaring(void_rule, [0, 3], kyoutaku: 2)
    expect(state.kyoutaku).to eq(3)
    result = ron(state, void_rule)

    expect(result.round_end_info[:winners]).to eq([{ seat: 3 }, { seat: 0 }])
    expect(state.scores[2]).to eq(25_000)
    expect(state.kyoutaku).to eq(2)
    expect(state.riichi_flags[2]).to be(false)
    _winner, score = win(state, 3, state.kyoutaku)
    expect(score.kyoutaku_bonus).to eq(2000)
  end

  it "宣言牌がチーされればリーチは成り立ち、後の打牌へのロンでも 1000 点は供託のまま" do
    state = declaring(void_rule, [])
    expect(state.pending_actions.keys).to eq([3])
    described_class.apply_action(state:, action: { type: :chi, seat: 3, tiles: %w[6s 7s] }, rule: void_rule)
    expect(state.scores[2]).to eq(24_000)
    expect(state.kyoutaku).to eq(1)
    expect(state.riichi_flags[2]).to be(true)

    # 席 3 が切った後、席 2 が自摸切りした 2p に席 0 がロンする（2p の単騎、断么九）
    described_class.apply_action(state:, action: { type: :dahai, seat: 3, tile: "1z" }, rule: void_rule)
    expect(state.phase).to eq(:tsumo)
    drawn = Mahjong::Tiles::Tile.new("2p")
    state.phase = :dahai
    state.current_seat = 2
    state.hands[2] = state.hands[2].add(drawn)
    state.last_tsumo = drawn
    state.hands[0] = Mahjong::State::Hand.new(tiles("2m 3m 4m 5p 6p 7p 3s 4s 5s 6s 7s 8s 2p"))
    described_class.apply_action(state:, action: { type: :dahai, seat: 2, tile: "2p" }, rule: void_rule)
    expect(state.pending_actions[0].map { |a| a[:type] }).to include(:ron_agari)
    ron(state, void_rule)

    expect(state.scores[2]).to eq(24_000)
    expect(state.kyoutaku).to eq(1)
    expect(state.riichi_flags[2]).to be(true)
  end

  it "宣言牌が見送られて通れば、リーチは成り立つ" do
    state = declaring(void_rule, [0])
    state.pending_actions.keys.each do |seat|
      described_class.apply_action(state:, action: { type: :skip, seat: }, rule: void_rule)
    end

    expect(state.phase).to eq(:tsumo)
    expect(state.scores[2]).to eq(24_000)
    expect(state.kyoutaku).to eq(1)
    expect(state.riichi_flags[2]).to be(true)
  end
end
