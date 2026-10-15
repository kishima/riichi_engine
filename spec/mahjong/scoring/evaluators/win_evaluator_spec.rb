require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Evaluators::WinEvaluator do
  let(:rule) { Mahjong::Config::RuleConfig.new }
  let(:snapshot) do
    Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze: "ton", oya_index: 0, honba: 0, kyoutaku: 0, jikaze: "nan")
  end

  def build_state(hand, dora_hyouji:, uradora_hyouji: "", riichi: false)
    Mahjong::State::RoundState.new.tap do |state|
      state.hands = { 0 => Mahjong::State::Hand.new([]), 1 => Mahjong::State::Hand.new(tiles(hand)),
                      2 => Mahjong::State::Hand.new([]), 3 => Mahjong::State::Hand.new([]) }
      state.dora_hyouji = tiles(dora_hyouji)
      state.uradora_hyouji = tiles(uradora_hyouji)
      state.riichi_flags[1] = riichi
      state.phase = :naki_wait
    end
  end

  def yaku_names(winner_info)
    winner_info[:yaku].to_h { |entry| [entry[:name], entry[:han]] }
  end

  def evaluate_tsumo(hand, agari:, jikaze: "nan", bakaze: "ton", riichi: false)
    state = Mahjong::State::RoundState.new
    state.hands = { 0 => Mahjong::State::Hand.new(tiles(hand)) }
    state.riichi_flags[0] = riichi
    state.first_turn_flags[0] = false
    state.dora_hyouji = []
    state.uradora_hyouji = []
    snapshot = Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze:, oya_index: 1, honba: 0, kyoutaku: 0, jikaze:)
    described_class.evaluate(state:, seat: 0, agari_type: :tsumo, agari_tile: Mahjong::Tiles::Tile.new(agari),
                             rule:, extra_flags: {}, snapshot:)
  end

  describe ".evaluate" do
    let(:hand) { "2m 3m 4m 6m 7m 3p 4p 5p 6s 7s 8s 2p 2p" }

    it "ドラはドラ表示牌の次の牌で数える" do
      state = build_state(hand, dora_hyouji: "1m")

      winner_info, = described_class.evaluate(state:, seat: 1, agari_type: :ron, agari_tile: Mahjong::Tiles::Tile.new("5m"),
                                              rule:, extra_flags: {}, snapshot:)

      expect(yaku_names(winner_info)["dora"]).to eq(1)
    end

    it "ドラ表示牌そのものはドラにならない" do
      state = build_state(hand, dora_hyouji: "2p")

      winner_info, = described_class.evaluate(state:, seat: 1, agari_type: :ron, agari_tile: Mahjong::Tiles::Tile.new("5m"),
                                              rule:, extra_flags: {}, snapshot:)

      expect(yaku_names(winner_info)["dora"]).to eq(1)
    end

    it "裏ドラも裏ドラ表示牌の次の牌で数える" do
      state = build_state(hand, dora_hyouji: "7z", uradora_hyouji: "2p", riichi: true)

      winner_info, = described_class.evaluate(state:, seat: 1, agari_type: :ron, agari_tile: Mahjong::Tiles::Tile.new("5m"),
                                              rule:, extra_flags: {}, snapshot:)

      expect(yaku_names(winner_info)["uradora"]).to eq(1)
      expect(yaku_names(winner_info)).not_to have_key("dora")
    end

    it "和了牌が単騎にも両面にも取れるときは高い方（平和）で評価する" do
      winner_info, = evaluate_tsumo("1s 2s 3s 3m 4m 5m 1p 2p 3p 3p 4p 5p 5m 5m", agari: "5m")

      expect(winner_info[:yaku].map { |entry| entry[:name] }).to include("pinfu")
      expect(winner_info[:fu]).to eq(20)
    end

    it "和了牌が両面にも嵌張にも取れるときは符の高い方で評価する" do
      # 567p の両面（30 符）より 678p の嵌張（40 符）の方が高い
      winner_info, score = evaluate_tsumo("5p 6p 7p 1s 2s 3s 6p 7p 8p 4z 4z 4z 9s 9s", agari: "7p",
                                          jikaze: "sha", bakaze: "nan", riichi: true)

      expect(winner_info[:fu]).to eq(40)
      expect(score.payments).to include(ko_pays: 700, oya_pays: 1300)
    end
  end
end
