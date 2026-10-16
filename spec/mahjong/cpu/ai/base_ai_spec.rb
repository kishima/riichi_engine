require_relative "../../../spec_helper"

RSpec.describe Mahjong::Cpu::Ai::BaseAi do
  let(:ai) { described_class.new(level: 2) }
  let(:rule) { Mahjong::Config::RuleConfig.new }
  let(:state) do
    Mahjong::State::RoundState.new.tap do |round_state|
      round_state.phase = :dahai
      round_state.current_seat = 0
      round_state.hands[0] = Mahjong::State::Hand.new(tiles("1m 2m 3m 1p 2p 3p 1s 2s 3s 4s 5s 6s 6z 7z"))
      round_state.last_tsumo = Mahjong::Tiles::Tile.new("7z")
      round_state.kawas = { 0 => Mahjong::State::Kawa.new, 1 => Mahjong::State::Kawa.new, 2 => Mahjong::State::Kawa.new, 3 => Mahjong::State::Kawa.new }
      round_state.fuuros = { 0 => [], 1 => [], 2 => [], 3 => [] }
      round_state.dora_hyouji = []
      round_state.wall = Mahjong::Tiles::Wall.new(Array.new(20) { Mahjong::Tiles::Tile.new("1m") })
    end
  end

  it "利用可能アクションがなければ nil を返す" do
    expect(ai.think(state:, seat: 0, available: [], rule:)).to be_nil
  end

  it "ツモ和了を最優先する" do
    available = [{ type: :tsumo_agari }, { type: :dahai, tile: "7z" }]

    expect(ai.think(state:, seat: 0, available:, rule:)).to eq(type: :tsumo_agari)
  end

  it "リーチ判断が通ればリーチを返す" do
    allow(Mahjong::Cpu::Judges::RiichiJudge).to receive(:should_riichi?).and_return(true)
    available = [{ type: :riichi, choices: ["7z"] }, { type: :dahai, tile: "9z" }]

    expect(ai.think(state:, seat: 0, available:, rule:)).to eq(type: :riichi, tile: "7z")
  end

  it "暗槓が可能なら暗槓を返す" do
    allow(Mahjong::Cpu::Judges::RiichiJudge).to receive(:should_riichi?).and_return(false)
    available = [{ type: :ankan, tile: "5m" }, { type: :dahai, tile: "9z" }]

    expect(ai.think(state:, seat: 0, available:, rule:)).to eq(type: :ankan, tile: "5m")
  end

  it "通常は打牌選択結果を返す" do
    allow(Mahjong::Cpu::Selectors::DahaiSelector).to receive(:select).and_return("7z")
    available = [{ type: :dahai, tile: "7z" }]

    expect(ai.think(state:, seat: 0, available:, rule:)).to eq(type: :dahai, tile: "7z")
  end

  it "リーチ中は自摸切りする" do
    state.riichi_flags[0] = true
    available = [{ type: :dahai, tile: "7z" }]

    expect(ai.think(state:, seat: 0, available:, rule:)).to eq(type: :dahai, tile: "7z")
  end

  it "鳴き待ちでは鳴き判断を使い、なければ skip する" do
    state.phase = :naki_wait
    allow(Mahjong::Cpu::Judges::NakiJudge).to receive(:judge).and_return(nil)

    expect(ai.think(state:, seat: 0, available: [{ type: :pon, tiles: %w[5m 5m] }], rule:)).to eq(type: :skip)
  end

  it "打牌の前の手でテンパイならリーチする（判断を差し替えない）" do
    easy = described_class.new(level: 1)
    state.scores[0] = 25_000
    available = [{ type: :riichi, choices: %w[6z 7z] }, { type: :dahai, tile: "7z" }]

    expect(easy.think(state:, seat: 0, available:, rule:)).to eq(type: :riichi, tile: "6z").or eq(type: :riichi, tile: "7z")
  end

  it "鳴いた手では、役の筋が消える暗槓はしない（断么九の手で 9m の暗槓）" do
    allow(Mahjong::Cpu::Judges::RiichiJudge).to receive(:should_riichi?).and_return(false)
    state.menzen_flags[0] = false
    state.fuuros[0] = [Mahjong::State::Fuuro.new(type: :chi, tiles: tiles("2p 3p 4p"), called_tile: Mahjong::Tiles::Tile.new("2p"), from_seat: 3)]
    state.hands[0] = Mahjong::State::Hand.new(tiles("9m 9m 9m 9m 3s 4s 5s 6s 7s 5p 5p"))
    available = [{ type: :ankan, tile: "9m" }, { type: :dahai, tile: "9m" }, { type: :dahai, tile: "7s" }]

    expect(ai.think(state:, seat: 0, available:, rule:)[:type]).to eq(:dahai)
  end

  it "鳴いた手でも、役の筋が残る暗槓はする" do
    allow(Mahjong::Cpu::Judges::RiichiJudge).to receive(:should_riichi?).and_return(false)
    state.menzen_flags[0] = false
    state.fuuros[0] = [Mahjong::State::Fuuro.new(type: :chi, tiles: tiles("2p 3p 4p"), called_tile: Mahjong::Tiles::Tile.new("2p"), from_seat: 3)]
    state.hands[0] = Mahjong::State::Hand.new(tiles("6m 6m 6m 6m 3s 4s 5s 6s 7s 5p 5p"))
    available = [{ type: :ankan, tile: "6m" }, { type: :dahai, tile: "6m" }]

    expect(ai.think(state:, seat: 0, available:, rule:)).to eq(type: :ankan, tile: "6m")
  end
end
