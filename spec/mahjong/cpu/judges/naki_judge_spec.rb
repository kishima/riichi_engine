require_relative "../../../spec_helper"

RSpec.describe Mahjong::Cpu::Judges::NakiJudge do
  def build_state(hand_str)
    Mahjong::State::RoundState.new.tap do |state|
      state.hands[1] = Mahjong::State::Hand.new(tiles(hand_str))
    end
  end

  it "ロンは常に選ぶ" do
    state = build_state("5m 5m 1p 2p")
    options = [{ type: :pon, tiles: %w[5m 5m] }, { type: :ron_agari }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 1)).to eq(type: :ron_agari)
  end

  it "初級は三元牌のポンだけを選ぶ" do
    state = build_state("5z 5z 1p 2p")
    options = [{ type: :pon, tiles: %w[5z 5z] }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 1)).to eq(type: :pon, tiles: %w[5z 5z])
  end

  it "初級は数牌のポンをスキップする" do
    state = build_state("5m 5m 1p 2p")
    options = [{ type: :pon, tiles: %w[5m 5m] }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 1)).to be_nil
  end

  it "中級は向聴が下がる鳴きを選ぶ" do
    # 3 向聴。7p を 6p 8p でチーすると 2 向聴（鳴いた面子は副露として数える）。
    state = build_state("2m 3m 5m 6m 7m 8m 2p 3p 6p 8p 5s 9s 1z")
    options = [{ type: :chi, tiles: %w[6p 8p] }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 2)).to eq(type: :chi, tiles: %w[6p 8p])
  end

  it "面子を崩すだけで向聴が下がらない鳴きは選ばない" do
    # 2 向聴。7p を 6p 8p でチーしても 567p を崩すので 2 向聴のまま。
    state = build_state("2m 3m 5m 6m 7m 8m 2p 3p 5p 6p 7p 8p 5s")
    options = [{ type: :chi, tiles: %w[6p 8p] }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 2)).to be_nil
  end

  it "テンパイ近辺では門前維持を優先する" do
    state = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 4s 5s 6s 7z")
    options = [{ type: :pon, tiles: %w[7z 7z] }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 2)).to be_nil
  end

  it "副露のある手の向聴数は副露を面子として数える（1 向聴なので鳴かない）" do
    # 副露 1 つ（ポン 5z）＋ 2m 3m 4m 6p 7p 1s 1s 8s 9s 2z: 1 向聴。
    # 副露を数えないと 3 向聴になり、1s をポンしてしまう。
    state = build_state("2m 3m 4m 6p 7p 1s 1s 8s 9s 2z")
    state.fuuros[1] = [Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5z 5z 5z"), called_tile: Mahjong::Tiles::Tile.new("5z"), from_seat: 0)]
    options = [{ type: :pon, tiles: %w[1s 1s] }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 2)).to be_nil
  end

  it "副露のある手で向聴が下がる鳴きを選ぶ" do
    # 副露 1 つ＋ 2m 3m 6p 7p 1s 1s 8s 2z 4z 6z: 2 向聴。5p のチー（6p 7p）で 1 向聴。
    state = build_state("2m 3m 6p 7p 1s 1s 8s 2z 4z 6z")
    state.fuuros[1] = [Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("5z 5z 5z"), called_tile: Mahjong::Tiles::Tile.new("5z"), from_seat: 0)]
    options = [{ type: :chi, tiles: %w[6p 7p] }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 2)).to eq(type: :chi, tiles: %w[6p 7p])
  end
end
