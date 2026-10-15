require_relative "../../../spec_helper"

RSpec.describe Mahjong::Flow::Detectors::NakiDetector do
  def build_state(hands:, kawas: nil)
    state = Mahjong::State::RoundState.new
    state.hands = hands.transform_values { |tiles_str| Mahjong::State::Hand.new(tiles(tiles_str)) }
    state.kawas = (kawas || {}).transform_values { |arr| Mahjong::State::Kawa.from_array(arr) }
    4.times { |seat| state.kawas[seat] ||= Mahjong::State::Kawa.new }
    state.riichi_flags = { 0 => false, 1 => false, 2 => false, 3 => false }
    state.instance_variable_set(:@dojun_furiten_flags, { 0 => false, 1 => false, 2 => false, 3 => false })
    state.instance_variable_set(:@riichi_furiten_flags, { 0 => false, 1 => false, 2 => false, 3 => false })
    def state.dojun_furiten_flags = @dojun_furiten_flags
    def state.riichi_furiten_flags = @riichi_furiten_flags
    state
  end

  it "ポン・チー・大明槓・ロンを検出する" do
    state = build_state(
      hands: {
        0 => "1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 4p",
        1 => "5m 5m 5m 2m 3m 4m 7p 8p 9p 1s 2s 3s 4z",
        2 => "4m 6m 2p 3p 4p 5p 6p 7p 8p 2s 3s 4s 5z",
        3 => "5m 5m 2m 3m 4m 3p 4p 5p 4s 5s 6s 6p 6p"
      }
    )

    result = described_class.detect(
      state: state,
      dahai_seat: 0,
      dahai_tile: Mahjong::Tiles::Tile.new("5m"),
      rule: Mahjong::Config::RuleConfig.new
    )

    expect(result[1].map { |a| a[:type] }).to include(:pon, :daiminkan, :chi)
    expect(result[2]).to be_nil
    expect(result[3].map { |a| a[:type] }).to include(:ron_agari)
    expect(result[3].map { |a| a[:type] }).not_to include(:chi)
  end

  it "フリテン時はロンを検出しない" do
    state = build_state(
      hands: {
        0 => "1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 4p",
        1 => "5m 5m 5m 2m 3m 4m 7p 8p 9p 1s 2s 3s 4z"
      },
      kawas: {
        1 => [{ tile: "5m" }]
      }
    )

    result = described_class.detect(
      state: state,
      dahai_seat: 0,
      dahai_tile: Mahjong::Tiles::Tile.new("5m"),
      rule: Mahjong::Config::RuleConfig.new
    )

    expect(result[1].map { |a| a[:type] }).not_to include(:ron_agari)
  end

  it "リーチ中はロン以外の鳴きを検出しない" do
    state = build_state(
      hands: {
        0 => "1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 4p",
        1 => "5m 5m 2m 3m 4m 7p 8p 9p 1s 2s 3s 4z 4z"
      }
    )
    state.riichi_flags[1] = true

    result = described_class.detect(
      state: state,
      dahai_seat: 0,
      dahai_tile: Mahjong::Tiles::Tile.new("5m"),
      rule: Mahjong::Config::RuleConfig.new
    )

    expect(result[1].map { |a| a[:type] }).to eq([:ron_agari])
  end

  it "海底ではロン以外の鳴きを検出しない" do
    state = build_state(
      hands: {
        0 => "1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 4p",
        1 => "5m 5m 5m 2m 3m 4m 7p 8p 9p 1s 2s 3s 4z",
        2 => "5m 5m 2m 3m 4m 7p 8p 9p 1s 2s 3s 4z 4z"
      }
    )
    state.wall = Mahjong::Tiles::Wall.new([])

    result = described_class.detect(
      state: state,
      dahai_seat: 0,
      dahai_tile: Mahjong::Tiles::Tile.new("5m"),
      rule: Mahjong::Config::RuleConfig.new
    )

    expect(result[1]).to be_nil
    # seat 2 は 5m のシャンポン待ちで、河底撈魚の 1 翻があるのでロンだけは出る
    expect(result[2].map { |a| a[:type] }).to eq([:ron_agari])
  end
end
