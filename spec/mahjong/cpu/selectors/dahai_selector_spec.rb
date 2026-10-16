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

  it "中級は同じ向聴なら受入の多い形を残す" do
    state = build_state
    hand = Mahjong::State::Hand.new(tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 2m 2m 3s 4s 6s"))

    tile = described_class.select(hand:, state:, level: 2)

    # 6s・9s 切りは 2s-5s の両面（8 枚）、3s 切りは 5s の嵌張（4 枚）
    expect(%w[6s 9s]).to include(tile)
  end

  it "上級も向聴の近い手では受入の多い形を残す" do
    state = build_state
    hand = Mahjong::State::Hand.new(tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 2m 2m 3s 4s 6s"))

    tile = described_class.select(hand:, state:, level: 3)

    expect(%w[6s 9s]).to include(tile)
  end

  it "上級は他家リーチ時に現物を優先する" do
    state = build_state
    state.riichi_flags[1] = true
    state.kawas[1].add("7z")
    hand = Mahjong::State::Hand.new(tiles("1m 2m 4m 5m 7m 8m 1p 2p 4p 5p 7p 8p 6z 7z"))

    tile = described_class.select(hand:, state:, level: 3)

    expect(tile).to eq("7z")
  end

  it "鳴いた後は副露を面子として数え、テンパイを保つ牌を切る" do
    state = build_state
    state.fuuros[0] = [Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5z 5z 5z"), called_tile: Mahjong::Tiles::Tile.new("5z"), from_seat: 3)]
    hand = Mahjong::State::Hand.new(tiles("2m 3m 7m 8m 9m 6p 7p 7p 6s 7s 8s"))

    [1, 2, 3].each do |level|
      expect(described_class.select(hand:, state:, level:)).to eq("6p")
    end
  end

  it "seat: で手の持ち主を指定できる（その席の副露を数える）" do
    state = build_state
    state.current_seat = 2
    state.fuuros[0] = [Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5z 5z 5z"), called_tile: Mahjong::Tiles::Tile.new("5z"), from_seat: 3)]
    hand = Mahjong::State::Hand.new(tiles("2m 3m 7m 8m 9m 6p 7p 7p 6s 7s 8s"))

    expect(described_class.select(hand:, state:, level: 2, seat: 0)).to eq("6p")
  end

  it "鳴いた手は役の筋に沿って切る（断么九の筋なら么九牌を切る）" do
    # 555m のポン＋ 23m 34p 234s 77p 8p 9p: 何を切っても 1 向聴の牌は複数あるが、
    # 断么九で数えて 1 向聴のままなのは 9p を切るときだけ。
    state = build_state
    state.menzen_flags[0] = false
    state.fuuros[0] = [Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5m 5m 5m"), called_tile: Mahjong::Tiles::Tile.new("5m"), from_seat: 1)]
    hand = Mahjong::State::Hand.new(tiles("2m 3m 3p 4p 2s 3s 4s 7p 7p 8p 9p"))

    expect(described_class.select(hand:, state:, level: 2, seat: 0)).to eq("9p")
    expect(described_class.select(hand:, state:, level: 3, seat: 0)).to eq("9p")
  end

  it "鳴いた手は、断么九の無いテンパイより筋に沿った 1 向聴を取る" do
    # 234p のチー＋ 45m 123s 567s 88m 9p: 9p を切ればテンパイ（3m・6m 待ち）だが 123s があって役が無い。
    # 断么九で数えるとどちらを切っても 1 向聴なので、通常の数え方でも 1 向聴になる 1s を切る。
    state = build_state
    state.menzen_flags[0] = false
    state.fuuros[0] = [Mahjong::State::Fuuro.new(type: :chi, tiles: tiles("2p 3p 4p"), called_tile: Mahjong::Tiles::Tile.new("2p"), from_seat: 3)]
    hand = Mahjong::State::Hand.new(tiles("4m 5m 1s 2s 3s 5s 6s 7s 8m 8m 9p"))

    expect(described_class.select(hand:, state:, level: 2, seat: 0)).to eq("1s")
  end
end
