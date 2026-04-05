require_relative "../../../spec_helper"

RSpec.describe Mahjong::Cpu::Selectors::DahaiSelector do
  def build_state
    Mahjong::State::RoundState.new.tap do |state|
      state.current_seat = 0
      state.kawas = { 0 => Mahjong::State::Kawa.new, 1 => Mahjong::State::Kawa.new, 2 => Mahjong::State::Kawa.new, 3 => Mahjong::State::Kawa.new }
      state.fuuros = { 0 => [], 1 => [], 2 => [], 3 => [] }
      state.dora_hyouji = []
      state.riichi_flags = { 0 => false, 1 => false, 2 => false, 3 => false }
    end
  end

  it "初級は向聴を維持しつつ字牌や端牌を優先して切る" do
    state = build_state
    hand = Mahjong::State::Hand.new(tiles("1m 2m 3m 4m 5m 6m 1p 2p 3p 1s 2s 3s 6z 7z"))

    tile = described_class.select(hand:, state:, level: 1)

    expect(%w[6z 7z]).to include(tile)
  end

  it "中級は受入の悪い牌を切る" do
    state = build_state
    hand = Mahjong::State::Hand.new(tiles("1m 2m 3m 4m 5m 6m 1p 2p 3p 1s 2s 3s 6z 7z"))

    tile = described_class.select(hand:, state:, level: 2)

    expect(tile).to eq("6z")
  end

  it "上級は他家リーチ時に現物を優先する" do
    state = build_state
    state.riichi_flags[1] = true
    state.kawas[1].add("7z")
    hand = Mahjong::State::Hand.new(tiles("1m 2m 4m 5m 7m 8m 1p 2p 4p 5p 7p 8p 6z 7z"))

    tile = described_class.select(hand:, state:, level: 3)

    expect(tile).to eq("7z")
  end
end
