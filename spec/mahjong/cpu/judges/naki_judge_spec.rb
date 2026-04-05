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
    state = build_state("2m 3m 5m 6m 7m 8m 2p 3p 5p 6p 7p 8p 5s")
    options = [{ type: :chi, tiles: %w[6p 8p] }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 2)).to eq(type: :chi, tiles: %w[6p 8p])
  end

  it "テンパイ近辺では門前維持を優先する" do
    state = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 4s 5s 6s 7z")
    options = [{ type: :pon, tiles: %w[7z 7z] }]

    expect(described_class.judge(naki_options: options, state:, seat: 1, level: 2)).to be_nil
  end
end
