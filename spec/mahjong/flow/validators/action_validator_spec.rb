require_relative "../../../spec_helper"

RSpec.describe Mahjong::Flow::Validators::ActionValidator do
  let(:state) { Mahjong::State::RoundState.new }
  let(:rule) { Mahjong::Config::RuleConfig.new }
  let(:action) { { type: :dahai, seat: 0, tile: "1m" } }

  before do
    state.phase = :dahai
    state.current_seat = 0
    state.hands = { 0 => Mahjong::State::Hand.new(tiles("1m 2m")) }
  end

  it "合法な打牌を valid と判定する" do
    expect(described_class.valid?(state:, action:, rule:)).to be true
  end

  it "フェーズ不一致を invalid と判定する" do
    state.phase = :tsumo

    result = described_class.validate(state:, action:, rule:)
    expect(result.valid?).to be false
  end

  it "未対応アクションを invalid と判定する" do
    result = described_class.validate(state:, action: { type: :pon, seat: 0 }, rule:)
    expect(result.valid?).to be false
  end

  it "naki_wait 中の pending pon を valid と判定する" do
    state.phase = :naki_wait
    state.pending_actions = { 1 => [{ type: :pon, tiles: %w[5m 5m] }] }

    result = described_class.validate(state:, action: { type: :pon, seat: 1, tiles: %w[5m 5m] }, rule:)
    expect(result.valid?).to be true
  end

  it "ankan 候補があれば valid と判定する" do
    state.hands = { 0 => Mahjong::State::Hand.new(tiles("5m 5m 5m 5m")) }

    result = described_class.validate(state:, action: { type: :ankan, seat: 0, tile: "5m" }, rule:)
    expect(result.valid?).to be true
  end

  it "九種九牌の条件を満たせば valid と判定する" do
    state.hands = { 0 => Mahjong::State::Hand.new(tiles("1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z")) }
    state.kawas = { 0 => Mahjong::State::Kawa.new }

    result = described_class.validate(state:, action: { type: :kyuushu_kyuuhai, seat: 0 }, rule:)
    expect(result.valid?).to be true
  end

  it "高優先度の ron がある間は pon を invalid と判定する" do
    state.phase = :naki_wait
    state.pending_actions = {
      1 => [{ type: :pon, tiles: %w[5m 5m] }],
      2 => [{ type: :ron_agari }]
    }

    result = described_class.validate(state:, action: { type: :pon, seat: 1, tiles: %w[5m 5m] }, rule:)
    expect(result.valid?).to be false
    expect(result.error).to eq("higher priority action exists")
  end

  it "リーチ中の pon を invalid と判定する" do
    state.phase = :naki_wait
    state.riichi_flags[1] = true
    state.pending_actions = { 1 => [{ type: :pon, tiles: %w[5m 5m] }] }

    result = described_class.validate(state:, action: { type: :pon, seat: 1, tiles: %w[5m 5m] }, rule:)

    expect(result.valid?).to be false
    expect(result.error).to eq("riichi player cannot call")
  end

  it "役なしの ron_agari を invalid と判定する" do
    state.phase = :naki_wait
    state.oya_seat = 0
    state.hands = {
      1 => Mahjong::State::Hand.new(tiles("1m 2m 3m 4m 5m 6m 7p 8p 9p 3s 4s 5s 7z"))
    }
    state.fuuros = { 1 => [] }
    state.pending_actions = { 1 => [{ type: :ron_agari }] }
    state.last_dahai = { seat: 0, tile: Mahjong::Tiles::Tile.new("7z") }

    result = described_class.validate(state:, action: { type: :ron_agari, seat: 1 }, rule:)

    expect(result.valid?).to be false
    expect(result.error).to eq("cannot ron agari")
  end
end
