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
  end
end
