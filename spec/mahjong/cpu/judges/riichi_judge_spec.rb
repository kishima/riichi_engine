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

  context "打牌の前の手（14 枚）" do
    it "テンパイを保つ打牌があればリーチする（切る牌を選んだ後の手で判断する）" do
      state = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 7s 8s 7z 7z 5z")

      expect(described_class.should_riichi?(state:, seat: 0, level: 1)).to be true
      expect(described_class.should_riichi?(state:, seat: 0, level: 2)).to be true
    end

    it "tile: で切る牌を指定すると、その牌を切った後の手で判断する" do
      state = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 7s 8s 7z 7z 5z")

      expect(described_class.should_riichi?(state:, seat: 0, level: 1, tile: "5z")).to be true
      expect(described_class.should_riichi?(state:, seat: 0, level: 1, tile: "1m")).to be false
    end

    it "テンパイを保つ打牌が無ければリーチしない" do
      state = build_state("1m 2m 3m 1p 2p 3p 1s 2s 3s 7s 9s 7z 6z 5z")

      expect(described_class.should_riichi?(state:, seat: 0, level: 1)).to be false
    end
  end

  describe ".riichi_tile" do
    it "待ちの残り枚数がいちばん多くなる牌を選ぶ" do
      # 9p 切りは 4s-7s 待ち（6 枚）、4s 切りと 7s 切りは 9p 単騎（3 枚）。
      state = build_state("1m 2m 3m 1p 2p 3p 7m 8m 9m 4s 5s 6s 7s 9p")

      expect(described_class.riichi_tile(state:, seat: 0, choices: %w[4s 7s 9p])).to eq("9p")
    end

    it "見えている牌は残り枚数から除く" do
      # 1z 切りは 2z 単騎、2z 切りは 1z 単騎。2z が河に 2 枚あれば 2z を切る（1z 単騎）。
      state = build_state("1m 2m 3m 1p 2p 3p 7m 8m 9m 4s 5s 6s 1z 2z")
      state.kawas[1].add("2z")
      state.kawas[2].add("2z")

      expect(described_class.riichi_tile(state:, seat: 0, choices: %w[1z 2z])).to eq("2z")
    end
  end
end
