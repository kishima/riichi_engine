require_relative "../../../spec_helper"

RSpec.describe Mahjong::Cpu::Judges::RiichiJudge do
  def build_state(hand_str, wall_tiles: 30)
    Mahjong::State::RoundState.new.tap do |state|
      state.hands[0] = Mahjong::State::Hand.new(tiles(hand_str))
      state.kawas = { 0 => Mahjong::State::Kawa.new, 1 => Mahjong::State::Kawa.new, 2 => Mahjong::State::Kawa.new, 3 => Mahjong::State::Kawa.new }
      state.fuuros = { 0 => [], 1 => [], 2 => [], 3 => [] }
      state.dora_hyouji = []
      state.wall = Mahjong::Tiles::Wall.new(Array.new(wall_tiles) { Mahjong::Tiles::Tile.new("1m") })
      state.scores[0] = 25_000
    end
  end

  it "条件不足ならリーチしない" do
    state = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 7s 8s 9s 7z")
    state.menzen_flags[0] = false

    expect(described_class.should_riichi?(state:, seat: 0, level: 1)).to be false
  end

  it "初級はテンパイならリーチする" do
    state = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 7s 8s 7z 7z")

    expect(described_class.should_riichi?(state:, seat: 0, level: 1)).to be true
  end

  it "中級は多面待ちのみリーチする" do
    good = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 7s 8s 7z 7z")
    bad = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 4s 5s 6s 7z")

    expect(described_class.should_riichi?(state: good, seat: 0, level: 2)).to be true
    expect(described_class.should_riichi?(state: bad, seat: 0, level: 2)).to be false
  end

  it "上級は追いかけ条件が悪いとダマに寄せる" do
    state = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 4s 5s 6s 7z", wall_tiles: 16)
    state.riichi_flags[1] = true
    state.riichi_flags[2] = true

    expect(described_class.should_riichi?(state:, seat: 0, level: 3)).to be false
  end
end
