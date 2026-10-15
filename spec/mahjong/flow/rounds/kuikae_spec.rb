require_relative "../../../spec_helper"

# 喰い替え。既定（kuikae: true）では鳴いた直後に何を切ってもよい（0.1.0 と同じ）。
# kuikae: false なら、ポンは鳴いた牌、チーは鳴いた牌と反対側の筋の牌を、鳴いた直後に切れない。
RSpec.describe Mahjong::Flow::Rounds::RoundFlow do
  let(:banned) { Mahjong::Config::RuleConfig.new("kuikae" => false) }
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

  # 席 0 が tile を自摸切りした直後（席 1 が鳴ける）。
  def after_discard(rule, tile, hand1)
    state = described_class.setup(game_snapshot: snapshot, rule:, seed: "kuikae")
    state.hands[0] = Mahjong::State::Hand.new(tiles("1z 1z 2z 2z 3z 3z 4z 4z 5z 5z 6z 6z 7z"))
    state.hands[1] = Mahjong::State::Hand.new(tiles(hand1))
    state.hands[2] = Mahjong::State::Hand.new(tiles("1s 1s 1s 2s 2s 2s 3s 3s 3s 4s 4s 4s 9m"))
    state.hands[3] = Mahjong::State::Hand.new(tiles("1p 1p 1p 2p 2p 2p 3p 3p 3p 4p 4p 4p 9m"))
    state.wall = Mahjong::Tiles::Wall.new(tiles(tile) + state.wall.tiles.drop(1))
    act(state, { type: :tsumo }, rule)
    act(state, { type: :dahai, seat: 0, tile: }, rule)
    state
  end

  def discards(state, seat, rule)
    described_class.available_actions(state:, seat:, rule:)
                   .select { |a| a[:type] == :dahai }.map { |a| a[:tile] }
  end

  def chi(state, seat, pair, rule)
    (state.pending_actions.keys - [seat]).each { |s| act(state, { type: :skip, seat: s }, rule) }
    act(state, { type: :chi, seat:, tiles: pair }, rule)
  end

  hand = "3m 4m 5m 6m 7p 8p 9p 1s 2s 7s 8s 9s 9p"

  it "既定のルールでは鳴いた直後に鳴いた牌も筋の牌も切れる" do
    state = after_discard(default_rule, "3m", hand)
    chi(state, 1, %w[4m 5m], default_rule)

    expect(discards(state, 1, default_rule)).to include("3m", "6m")
  end

  it "kuikae: false なら 45m で 3m をチーした直後に 3m と 6m を切れない" do
    state = after_discard(banned, "3m", hand)
    chi(state, 1, %w[4m 5m], banned)

    expect(discards(state, 1, banned)).not_to include("3m", "6m")
    expect(discards(state, 1, banned)).to include("7p")
    expect { act(state, { type: :dahai, seat: 1, tile: "6m" }, banned) }
      .to raise_error(Mahjong::Errors::InvalidActionError, /kuikae/)
  end

  it "45m で 6m をチーした直後は 6m と 3m、嵌張のチー（35m に 4m）は 4m だけ切れない" do
    state = after_discard(banned, "6m", "3m 4m 5m 6m 7p 8p 9p 1s 2s 7s 8s 9s 9p")
    chi(state, 1, %w[4m 5m], banned)
    expect(discards(state, 1, banned)).not_to include("3m", "6m")

    state = after_discard(banned, "4m", "3m 5m 4m 6m 7p 8p 9p 1s 2s 7s 8s 9s 9p")
    chi(state, 1, %w[3m 5m], banned)
    expect(discards(state, 1, banned)).not_to include("4m")
    expect(discards(state, 1, banned)).to include("6m")
  end

  it "ポンの直後は鳴いた牌と同じ種類（赤五も）を切れない" do
    state = after_discard(banned, "5p", "5p 0p 1m 2m 3m 7s 8s 9s 1z 1z 2z 3z 4z")
    (state.pending_actions.keys - [1]).each { |s| act(state, { type: :skip, seat: s }, banned) }
    act(state, { type: :pon, seat: 1, tiles: %w[5p 0p] }, banned)

    expect(discards(state, 1, banned).grep(/[05]p/)).to eq([])
  end

  it "鳴いた後に切れる牌が残らないチーは出さない" do
    state = after_discard(banned, "3m", "4m 5m 6m 6m 7p 8p 9p 1s 2s 3s 7s 8s 9s")
    state2 = after_discard(banned, "3m", "4m 5m 6m 6m 7p 8p 9p 1s 2s 3s 7s 8s 9s")
    # 席 1 の手を 4 枚にして、副露 3 つを持たせる（チーの後に 6m 6m しか残らない）
    [state, state2].each do |st|
      st.hands[1] = Mahjong::State::Hand.new(tiles("4m 5m 6m 6m"))
      st.fuuros[1] = 3.times.map { Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("1z 1z 1z"), called_tile: Mahjong::Tiles::Tile.new("1z"), from_seat: 0) }
    end
    detect = ->(st, rule) { Mahjong::Flow::Detectors::NakiDetector.detect(state: st, dahai_seat: 0, dahai_tile: Mahjong::Tiles::Tile.new("3m"), rule:) }

    expect(Array(detect.(state, banned)[1]).map { |a| a[:type] }).not_to include(:chi)
    expect(Array(detect.(state2, default_rule)[1]).map { |a| a[:type] }).to include(:chi)
  end

  it "CPU は喰い替えにならない牌を切る" do
    state = after_discard(banned, "3m", "3m 4m 5m 6m 7p 8p 9p 1s 2s 7s 8s 9s 9p")
    chi(state, 1, %w[4m 5m], banned)
    ai = Mahjong::Cpu::Ai::BaseAi.new(level: 2)
    available = described_class.available_actions(state:, seat: 1, rule: banned)
    action = ai.think(state:, seat: 1, available:, rule: banned)

    expect(action[:type]).to eq(:dahai)
    expect(%w[3m 6m]).not_to include(action[:tile])
    expect { act(state, action.merge(seat: 1), banned) }.not_to raise_error
  end
end
