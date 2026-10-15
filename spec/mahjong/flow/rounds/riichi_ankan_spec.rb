require_relative "../../../spec_helper"

# リーチ後の暗槓。既定（riichi_ankan: false）ではリーチ後に暗槓できない（0.1.0 と同じ）。
# riichi_ankan: true なら、自摸った牌の暗槓で、待ちの牌の種類が変わらないときだけできる。
RSpec.describe Mahjong::Flow::Rounds::RoundFlow do
  let(:allowed) { Mahjong::Config::RuleConfig.new("riichi_ankan" => true) }
  let(:default_rule) { Mahjong::Config::RuleConfig.new }
  let(:snapshot) do
    Mahjong::Snapshots::GameSetupSnapshot.new(
      bakaze: "ton", kyoku: 1, honba: 0, kyoutaku: 0, oya_index: 0,
      scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
    )
  end

  # 席 0 がリーチ中で draw を自摸った局面。
  def riichi_with(hand, draw, rule)
    state = described_class.setup(game_snapshot: snapshot, rule:, seed: "riichi-ankan")
    state.hands[0] = Mahjong::State::Hand.new(tiles(hand))
    state.riichi_flags[0] = true
    state.ippatsu_flags[0] = true
    state.first_turn_flags[0] = false
    state.wall = Mahjong::Tiles::Wall.new(tiles(draw) + state.wall.tiles.drop(1))
    described_class.apply_action(state:, action: { type: :tsumo }, rule:)
    state
  end

  def ankans(state, rule)
    described_class.available_actions(state:, seat: 0, rule:).select { |a| a[:type] == :ankan }.map { |a| a[:tile] }
  end

  # 111m 234p 567s 99s 45m（待ち 3m・6m）に 1m を自摸る: 槓の後も待ちは 3m・6m
  same_waits = "1m 1m 1m 2p 3p 4p 5s 6s 7s 9s 9s 4m 5m"

  it "既定のルールではリーチ後に暗槓できない" do
    state = riichi_with(same_waits, "1m", default_rule)

    expect(ankans(state, default_rule)).to eq([])
  end

  it "riichi_ankan なら、待ちが変わらない自摸った牌の暗槓ができる" do
    state = riichi_with(same_waits, "1m", allowed)
    expect(ankans(state, allowed)).to eq(["1m"])

    described_class.apply_action(state:, action: { type: :ankan, seat: 0, tile: "1m" }, rule: allowed)
    expect(state.fuuros[0].last.type).to eq(:ankan)
    expect(state.riichi_flags[0]).to be(true)
    expect(state.ippatsu_flags[0]).to be(false)
  end

  it "待ちが変わる暗槓はできない（333m 45m は 3m・6m・9s 待ち、槓の後は 3m・6m）" do
    state = riichi_with("3m 3m 3m 4m 5m 6p 7p 8p 5s 6s 7s 9s 9s", "3m", allowed)

    expect(ankans(state, allowed)).to eq([])
    expect { described_class.apply_action(state:, action: { type: :ankan, seat: 0, tile: "3m" }, rule: allowed) }
      .to raise_error(Mahjong::Errors::InvalidActionError)
  end

  it "自摸った牌でない 4 枚の暗槓（送り槓）はできない" do
    state = riichi_with("2p 2p 2p 2p 3p 4p 5s 6s 7s 9s 9s 4m 5m", "7z", allowed)

    expect(ankans(state, allowed)).to eq([])
  end

  it "リーチしていなければ今までどおり" do
    state = riichi_with("3m 3m 3m 4m 5m 6p 7p 8p 5s 6s 7s 9s 9s", "3m", allowed)
    state.riichi_flags[0] = false

    expect(ankans(state, allowed)).to eq(["3m"])
  end
end
