require_relative "../../../spec_helper"

# 同巡内フリテン。和了牌を見逃した席は、次の自分のツモ番までロンできない。
# 役が無くてロンの候補が出ない待ちの牌でも、見逃しは見逃し（フリテンは待ちで決まり、役の有無は見ない）。
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

  def ron_offered?(state, seat)
    Array(state.pending_actions[seat]).any? { |a| a[:type] == :ron_agari }
  end

  # 席 3 は 222m 567p 678s 23s 88p の 1s・4s 待ち。4s なら断幺九、1s では役が無い（刻子があるので平和でもない）。
  # 牌山の先頭から席 0・1・2・3 の自摸になる。ほかの席は鳴けない手。
  def table(draws)
    state = described_class.setup(game_snapshot: snapshot, rule:, seed: "dojun")
    state.hands[0] = Mahjong::State::Hand.new(tiles("1z 1z 2z 2z 3z 3z 4z 4z 5z 5z 6z 6z 7z"))
    state.hands[1] = Mahjong::State::Hand.new(tiles("1p 1p 1p 2p 2p 2p 3p 3p 3p 7m 9m 5z 6z"))
    state.hands[2] = Mahjong::State::Hand.new(tiles("7z 7z 7z 9s 9s 9s 1m 1m 1m 3m 3m 3m 9m"))
    state.hands[3] = Mahjong::State::Hand.new(tiles("2m 2m 2m 5p 6p 7p 6s 7s 8s 2s 3s 8p 8p"))
    state.wall = Mahjong::Tiles::Wall.new(tiles(draws) + state.wall.tiles.drop(draws.split.size))
    state
  end

  # seat が自摸って tile を切る（自摸切り）。
  def draw_and_discard(state, seat, tile)
    act(state, { type: :tsumo })
    act(state, { type: :dahai, seat:, tile: })
  end

  it "役の無い和了牌（1s）を見逃した席は、同じ巡のうちは役のある和了牌（4s）でもロンできない" do
    state = table("1s 4s")
    draw_and_discard(state, 0, "1s")
    expect(state.phase).to eq(:tsumo) # 1s にはロンの候補が出ない（役が無い）
    expect(state.dojun_furiten_flags[3]).to be true

    draw_and_discard(state, 1, "4s")
    expect(ron_offered?(state, 3)).to be false
  end

  it "見逃しの後でも、自分のツモ番が来ればロンできる" do
    state = table("1s 9p 9m 9m 4s")
    draw_and_discard(state, 0, "1s")
    draw_and_discard(state, 1, "9p")
    draw_and_discard(state, 2, "9m")
    draw_and_discard(state, 3, "9m")
    expect(state.dojun_furiten_flags[3]).to be false

    draw_and_discard(state, 0, "4s")
    expect(ron_offered?(state, 3)).to be true
  end

  it "待ちでない牌ではフリテンにならない" do
    state = table("9p 4s")
    draw_and_discard(state, 0, "9p")
    expect(state.dojun_furiten_flags[3]).to be false

    draw_and_discard(state, 1, "4s")
    expect(ron_offered?(state, 3)).to be true
  end

  it "役のある和了牌の見逃しは前と同じく同巡内フリテン" do
    state = table("4s 4s")
    draw_and_discard(state, 0, "4s")
    expect(ron_offered?(state, 3)).to be true
    act(state, { type: :skip, seat: 3 })
    expect(state.dojun_furiten_flags[3]).to be true

    draw_and_discard(state, 1, "4s")
    expect(ron_offered?(state, 3)).to be false
  end
end
