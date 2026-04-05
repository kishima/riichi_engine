require_relative "../../spec_helper"

RSpec.describe Mahjong::State::RoundState do
  it "初期値を持つ" do
    state = described_class.new

    expect(state.phase).to eq(:tsumo)
    expect(state.junme).to eq(0)
    expect(state.scores).to eq({ 0 => 25000, 1 => 25000, 2 => 25000, 3 => 25000 })
    expect(state.is_menzen?(0)).to be true
    expect(state.is_riichi?(0)).to be false
    expect(state.state_version).to eq(0)
  end

  it "壁残枚数から海底を判定する" do
    wall = instance_double(Mahjong::Tiles::Wall, remaining: 0)
    state = described_class.new
    state.wall = wall

    expect(state.is_haitei?).to be true
    state.phase = :naki_wait
    expect(state.is_houtei?).to be true
  end

  it "JSON シリアライズと復元ができる" do
    state = described_class.new
    state.bakaze = "ton"
    state.kyoku = 1
    state.honba = 2
    state.current_seat = 3
    state.state_version = 7
    state.hands = { 0 => Mahjong::State::Hand.new(tiles("1m 2m")) }
    state.kawas = { 0 => Mahjong::State::Kawa.from_array([{ tile: "3m", tsumogiri: true }]) }
    state.fuuros = { 0 => [Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5m 5m 5m"))] }
    state.wall = Mahjong::Tiles::Wall.new(tiles("1p 2p 3p"))
    state.wanpai = Mahjong::Tiles::Wanpai.from_hash(
      rinshan: %w[1s 2s 3s 4s],
      dora_hyouji: %w[1z],
      uradora_hyouji: %w[2z],
      remaining_dora: %w[3z 4z],
      remaining_uradora: %w[5z 6z]
    )
    state.last_dahai = { seat: 0, tile: Mahjong::Tiles::Tile.new("3m") }
    state.last_tsumo = Mahjong::Tiles::Tile.new("4m")
    state.pending_actions = { 1 => [{ type: :pon, tiles: %w[5m 5m] }, { type: :skip }] }

    restored = described_class.from_json(state.to_json)

    expect(restored.bakaze).to eq("ton")
    expect(restored.state_version).to eq(7)
    expect(restored.hands[0].to_a).to eq(%w[1m 2m])
    expect(restored.kawas[0].to_a.first[:tile]).to eq("3m")
    expect(restored.fuuros[0].first).to be_pon
    expect(restored.wall.remaining).to eq(3)
    expect(restored.wanpai.rinshan_remaining).to eq(4)
    expect { restored.wanpai.reveal_new_dora! }.not_to raise_error
    expect(restored.last_dahai[:tile].to_s).to eq("3m")
    expect(restored.last_tsumo.to_s).to eq("4m")
    expect(restored.pending_actions).to eq({ 1 => [{ type: :pon, tiles: %w[5m 5m] }, { type: :skip }] })
  end
end
