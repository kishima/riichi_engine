require_relative "../../../spec_helper"

RSpec.describe Mahjong::Flow::Rounds::RoundFlow do
  let(:rule) { Mahjong::Config::RuleConfig.new }
  let(:game_snapshot) do
    Mahjong::Snapshots::GameSetupSnapshot.new(
      bakaze: "ton",
      kyoku: 1,
      honba: 0,
      kyoutaku: 0,
      oya_index: 0,
      scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
    )
  end
  let(:state) { Mahjong::State::RoundState.new }
  let(:action) { { type: :dahai, seat: 0, tile: "1m" } }

  it ".setup で局の初期状態を構築する" do
    result = described_class.setup(game_snapshot:, rule:, seed: "test-seed")

    expect(result.phase).to eq(:tsumo)
    expect(result.current_seat).to eq(0)
    expect(result.wall.remaining).to eq(70)
    expect(result.wanpai.rinshan_remaining).to eq(4)
    expect(result.hands.values.map(&:count)).to all(eq(13))
    expect(result.kawas.values).to all(be_a(Mahjong::State::Kawa))
    expect(result.scores).to eq({ 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 })
  end

  it ".apply_action は D09 まで未実装" do
    expect { described_class.apply_action(state:, action:, rule:) }.to raise_error(Mahjong::Errors::InvalidActionError)
  end

  it ".available_actions は dahai フェーズで打牌候補を返す" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "flow-seed")
    described_class.apply_action(state: flow_state, action: { type: :tsumo }, rule:)

    actions = described_class.available_actions(state: flow_state, seat: flow_state.current_seat, rule:)
    expect(actions).not_to be_empty
    expect(actions).to all(include(:type))
    expect(actions.map { |a| a[:type] }).to include(:dahai)
  end

  it "tsumo -> dahai -> 次プレイヤーの tsumo 待ちへ進む" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "flow-seed")

    tsumo_result = described_class.apply_action(state: flow_state, action: { type: :tsumo }, rule:)
    expect(tsumo_result.events.first[:type]).to eq(:tsumo)
    expect(flow_state.phase).to eq(:dahai)
    expect(flow_state.hands[0].count).to eq(14)

    tile = flow_state.hands[0].tiles.first.to_s
    dahai_result = described_class.apply_action(state: flow_state, action: { type: :dahai, seat: 0, tile: tile }, rule:)
    expect(dahai_result.events.first[:type]).to eq(:dahai)
    expect(flow_state.kawas[0].count).to eq(1)
    expect([:tsumo, :naki_wait]).to include(flow_state.phase)
  end

  it "skip で鳴き待ちを解消すると次巡へ進む" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "skip-seed")
    4.times { |seat| flow_state.hands[seat] = Mahjong::State::Hand.new([]) }
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("5m"))
    flow_state.hands[1] = Mahjong::State::Hand.new(tiles("5m 5m"))
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new("5m")

    described_class.apply_action(state: flow_state, action: { type: :dahai, seat: 0, tile: "5m" }, rule:)
    expect(flow_state.phase).to eq(:naki_wait)

    described_class.apply_action(state: flow_state, action: { type: :skip, seat: 1 }, rule:)
    expect(flow_state.phase).to eq(:tsumo)
    expect(flow_state.current_seat).to eq(1)
  end

  it "pon 成立後は鳴いた人の打牌番になる" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "pon-seed")
    4.times { |seat| flow_state.hands[seat] = Mahjong::State::Hand.new([]) }
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("5m"))
    flow_state.hands[1] = Mahjong::State::Hand.new(tiles("5m 5m 3p"))
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new("5m")

    described_class.apply_action(state: flow_state, action: { type: :dahai, seat: 0, tile: "5m" }, rule:)
    described_class.apply_action(state: flow_state, action: { type: :pon, seat: 1, tiles: %w[5m 5m] }, rule:)

    expect(flow_state.current_seat).to eq(1)
    expect(flow_state.phase).to eq(:dahai)
    expect(flow_state.fuuros[1].size).to eq(1)
    expect(flow_state.kawas[0].to_a.last[:called]).to be true
  end

  it "chi 成立後は鳴いた人の打牌番になる" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "chi-seed")
    4.times { |seat| flow_state.hands[seat] = Mahjong::State::Hand.new([]) }
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("5m"))
    flow_state.hands[1] = Mahjong::State::Hand.new(tiles("4m 6m 3p"))
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new("5m")

    described_class.apply_action(state: flow_state, action: { type: :dahai, seat: 0, tile: "5m" }, rule:)
    described_class.apply_action(state: flow_state, action: { type: :chi, seat: 1, tiles: %w[4m 6m] }, rule:)

    expect(flow_state.current_seat).to eq(1)
    expect(flow_state.phase).to eq(:dahai)
    expect(flow_state.fuuros[1].size).to eq(1)
    expect(flow_state.fuuros[1].first).to be_chi
  end

  it "riichi で供託とフラグが立ち、打牌後も打牌待ちに入る" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "riichi-seed")
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 3z"))
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new("3z")

    described_class.apply_action(state: flow_state, action: { type: :riichi, seat: 0, tile: "3z" }, rule:)

    expect(flow_state.riichi_flags[0]).to be true
    expect(flow_state.ippatsu_flags[0]).to be true
    expect(flow_state.kyoutaku).to eq(1)
    expect(flow_state.scores[0]).to eq(24_000)
    expect([:tsumo, :naki_wait]).to include(flow_state.phase)
    expect(flow_state.kawas[0].to_a.last[:riichi]).to be true
  end

  it "リーチ後の available_actions は自摸切りと自摸和了以外を返さない" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "riichi-limit-seed")
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.riichi_flags[0] = true
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("1m 2m 3m"))
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new("3m")

    actions = described_class.available_actions(state: flow_state, seat: 0, rule:)

    expect(actions).to eq([{ type: :dahai, tile: "3m" }])
  end

  it "リーチ後は自摸切りで手番が進み、ほかの牌は切れない" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "riichi-tsumogiri-seed")
    4.times { |seat| flow_state.hands[seat] = Mahjong::State::Hand.new([]) }
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.riichi_flags[0] = true
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s 1z"))
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new("1z")

    expect do
      described_class.apply_action(state: flow_state, action: { type: :dahai, seat: 0, tile: "9m" }, rule:)
    end.to raise_error(Mahjong::Errors::InvalidActionError, /drawn tile/)

    described_class.apply_action(state: flow_state, action: { type: :dahai, seat: 0, tile: "1z" }, rule:)

    expect(flow_state.kawas[0].to_a.last[:tile]).to eq("1z")
    expect(flow_state.phase).to eq(:tsumo)
    expect(flow_state.current_seat).to eq(1)
  end

  it "リーチ中のロン待ちではロン以外を返さない" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "riichi-ron-seed")
    flow_state.phase = :naki_wait
    flow_state.current_seat = 0
    flow_state.riichi_flags[1] = true
    flow_state.pending_actions = { 1 => [{ type: :ron_agari }, { type: :pon, tiles: %w[5m 5m] }] }

    actions = described_class.available_actions(state: flow_state, seat: 1, rule:)

    expect(actions).to eq([{ type: :ron_agari }])
  end

  it "残り4枚未満ではリーチできない" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "riichi-wall-limit-seed")
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 3z"))
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new("3z")
    flow_state.wall = Mahjong::Tiles::Wall.new(tiles("1m 2m 3m"))

    actions = described_class.available_actions(state: flow_state, seat: 0, rule:)

    expect(actions).not_to include(include(type: :riichi))
  end

  it "ankan で副露化し嶺上牌を引く" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "ankan-seed")
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("5m 5m 5m 5m 1p 2p 3p 4p 5p 6p 7p 8p 9p"))
    before_dora = flow_state.dora_hyouji.size

    described_class.apply_action(state: flow_state, action: { type: :ankan, seat: 0, tile: "5m" }, rule:)

    expect(flow_state.fuuros[0].last).to be_ankan
    expect(flow_state.hands[0].count).to eq(10)
    expect(flow_state.last_tsumo).to be_a(Mahjong::Tiles::Tile)
    expect(flow_state.dora_hyouji.size).to eq(before_dora + 1)
    expect(flow_state.rinshan_flag).to be true
  end

  it "daiminkan で副露化し嶺上牌を引く" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "daiminkan-seed")
    4.times { |seat| flow_state.hands[seat] = Mahjong::State::Hand.new([]) }
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("5m"))
    flow_state.hands[1] = Mahjong::State::Hand.new(tiles("5m 5m 5m 3p"))
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new("5m")

    described_class.apply_action(state: flow_state, action: { type: :dahai, seat: 0, tile: "5m" }, rule:)
    described_class.apply_action(state: flow_state, action: { type: :daiminkan, seat: 1 }, rule:)

    expect(flow_state.fuuros[1].last).to be_daiminkan
    expect(flow_state.current_seat).to eq(1)
    expect(flow_state.last_tsumo).to be_a(Mahjong::Tiles::Tile)
    expect(flow_state.kawas[0].to_a.last[:called]).to be true
  end

  it "kakan でポンを加槓に更新する" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "kakan-seed")
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("5m 1p 2p 3p"))
    flow_state.fuuros[0] = [
      Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5m 5m 5m"), called_tile: Mahjong::Tiles::Tile.new("5m"), from_seat: 1)
    ]

    described_class.apply_action(state: flow_state, action: { type: :kakan, seat: 0, tile: "5m" }, rule:)

    expect(flow_state.fuuros[0].last).to be_kakan
    expect(flow_state.hands[0].count).to eq(4)
    expect(flow_state.last_tsumo).to be_a(Mahjong::Tiles::Tile)
    expect(flow_state.chankan_tile).to be_nil
  end

  it "kakan 後に槍槓可能なら ron 待ちに入る" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "kakan-chankan-seed")
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("5m 1p 2p 3p"))
    flow_state.hands[1] = Mahjong::State::Hand.new(tiles("2m 3m 4m 5p 6p 7p 3s 4s 5s 6s 7s 8s 5m"))
    flow_state.fuuros[0] = [
      Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5m 5m 5m"), called_tile: Mahjong::Tiles::Tile.new("5m"), from_seat: 1)
    ]

    result = described_class.apply_action(state: flow_state, action: { type: :kakan, seat: 0, tile: "5m" }, rule:)

    expect(result.events.first[:type]).to eq(:kakan)
    expect(flow_state.phase).to eq(:naki_wait)
    expect(flow_state.pending_actions[1]).to eq([{ type: :ron_agari }])
    expect(flow_state.last_tsumo).to be_nil
  end

  it "槍槓が流れた kakan は嶺上牌を引いて続行する" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "kakan-finalize-seed")
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("5m 1p 2p 3p"))
    flow_state.hands[1] = Mahjong::State::Hand.new(tiles("2m 3m 4m 5p 6p 7p 3s 4s 5s 6s 7s 8s 5m"))
    flow_state.fuuros[0] = [
      Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5m 5m 5m"), called_tile: Mahjong::Tiles::Tile.new("5m"), from_seat: 1)
    ]

    described_class.apply_action(state: flow_state, action: { type: :kakan, seat: 0, tile: "5m" }, rule:)
    described_class.apply_action(state: flow_state, action: { type: :skip, seat: 1 }, rule:)

    expect(flow_state.phase).to eq(:dahai)
    expect(flow_state.current_seat).to eq(0)
    expect(flow_state.last_tsumo).to be_a(Mahjong::Tiles::Tile)
    expect(flow_state.rinshan_flag).to be true
    expect(flow_state.chankan_tile).to be_nil
    expect(flow_state.pending_actions).to eq({})
  end

  it "tsumo_agari で round_end になる" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "agari-seed")
    winning = hand_fixture(:menzen_tsumo_only)
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("#{winning[:hand]} #{winning[:agari_hai]}"))
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new(winning[:agari_hai])

    result = described_class.apply_action(state: flow_state, action: { type: :tsumo_agari, seat: 0 }, rule:)

    expect(result).to be_round_end
    expect(result.round_end_info[:type]).to eq(:tsumo_agari)
    expect(result.round_end_info[:winner_seat]).to eq(0)
  end

  it "ron_agari で round_end になる" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "ron-seed")
    flow_state.phase = :naki_wait
    flow_state.current_seat = 0
    flow_state.last_dahai = { seat: 0, tile: Mahjong::Tiles::Tile.new("8s") }
    flow_state.hands[1] = Mahjong::State::Hand.new(tiles("2m 3m 4m 5p 6p 7p 3s 4s 5s 6s 7s 2p 2p"))
    flow_state.pending_actions = { 1 => [{ type: :ron_agari }] }

    result = described_class.apply_action(state: flow_state, action: { type: :ron_agari, seat: 1 }, rule:)

    expect(result).to be_round_end
    expect(result.round_end_info[:type]).to eq(:ron_agari)
    expect(result.round_end_info[:winner_seat]).to eq(1)
    expect(result.round_end_info[:loser_seat]).to eq(0)
  end

  it "高優先度者が skip した後は下位の pon を実行できる" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "priority-seed")
    flow_state.phase = :naki_wait
    flow_state.current_seat = 0
    flow_state.last_dahai = { seat: 0, tile: Mahjong::Tiles::Tile.new("5m") }
    flow_state.pending_actions = {
      1 => [{ type: :pon, tiles: %w[5m 5m] }],
      2 => [{ type: :ron_agari }]
    }
    flow_state.hands[1] = Mahjong::State::Hand.new(tiles("5m 5m 3p"))

    described_class.apply_action(state: flow_state, action: { type: :skip, seat: 2 }, rule:)
    result = described_class.apply_action(state: flow_state, action: { type: :pon, seat: 1, tiles: %w[5m 5m] }, rule:)

    expect(result.events.first[:type]).to eq(:pon)
    expect(flow_state.current_seat).to eq(1)
    expect(flow_state.phase).to eq(:dahai)
  end

  it "役なしロン見送りでは同巡フリテンを付けない" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "skip-no-yaku-seed")
    flow_state.phase = :naki_wait
    flow_state.current_seat = 0
    flow_state.oya_seat = 0
    flow_state.last_dahai = { seat: 0, tile: Mahjong::Tiles::Tile.new("7z") }
    flow_state.hands[2] = Mahjong::State::Hand.new(tiles("1m 2m 3m 4m 5m 6m 7p 8p 9p 3s 4s 5s 7z"))
    flow_state.fuuros[2] = []
    flow_state.pending_actions = { 2 => [{ type: :ron_agari }] }

    described_class.apply_action(state: flow_state, action: { type: :skip, seat: 2 }, rule:)

    expect(flow_state.dojun_furiten_flags[2]).to be false
    expect(flow_state.riichi_furiten_flags[2]).to be false
  end

  it "嶺上フラグは次の通常打牌でクリアされる" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "rinshan-clear-seed")
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("1m 2m 3m"))
    flow_state.last_tsumo = Mahjong::Tiles::Tile.new("3m")
    flow_state.rinshan_flag = true
    flow_state.chankan_tile = Mahjong::Tiles::Tile.new("5m")

    described_class.apply_action(state: flow_state, action: { type: :dahai, seat: 0, tile: "3m" }, rule:)

    expect(flow_state.rinshan_flag).to be false
    expect(flow_state.chankan_tile).to be_nil
  end

  it "壁が尽きている場合の tsumo は荒牌平局になる" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "draw-seed")
    flow_state.wall = Mahjong::Tiles::Wall.new([])

    result = described_class.apply_action(state: flow_state, action: { type: :tsumo }, rule:)

    expect(result).to be_round_end
    expect(result.round_end_info[:type]).to eq(:ryuukyoku)
  end

  it "九種九牌で round_end になる" do
    flow_state = described_class.setup(game_snapshot:, rule:, seed: "kyuushu-seed")
    flow_state.phase = :dahai
    flow_state.current_seat = 0
    flow_state.hands[0] = Mahjong::State::Hand.new(tiles("1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z"))
    flow_state.kawas[0] = Mahjong::State::Kawa.new

    result = described_class.apply_action(state: flow_state, action: { type: :kyuushu_kyuuhai, seat: 0 }, rule:)

    expect(result).to be_round_end
    expect(result.round_end_info[:type]).to eq(:kyuushu_kyuuhai)
  end
end
