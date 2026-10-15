require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Evaluators::WinEvaluator do
  let(:snapshot) do
    Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze: "ton", oya_index: 0, honba: 0, kyoutaku: 0, jikaze: "nan")
  end

  # 大三元・字一色の 2 つが重なる手（中と南の双碰、中でロン）。
  def build_state
    Mahjong::State::RoundState.new.tap do |state|
      state.hands = { 0 => Mahjong::State::Hand.new([]), 1 => Mahjong::State::Hand.new(tiles("5z 5z 5z 6z 6z 6z 7z 7z 1z 1z 1z 2z 2z")),
                      2 => Mahjong::State::Hand.new([]), 3 => Mahjong::State::Hand.new([]) }
      state.dora_hyouji = []
      state.uradora_hyouji = []
      state.phase = :naki_wait
    end
  end

  def evaluate(rule)
    described_class.evaluate(state: build_state, seat: 1, agari_type: :ron, agari_tile: Mahjong::Tiles::Tile.new("7z"),
                             rule:, extra_flags: {}, snapshot:)
  end

  describe "役満の重なり" do
    it "multiple_yakuman が偽（既定）なら役満 1 つとして数える" do
      winner_info, score = evaluate(Mahjong::Config::RuleConfig.new)

      expect(winner_info[:yaku].map { |entry| entry[:name] }).to contain_exactly("daisangen", "tsuuiisou")
      expect(score.payments[:ron_pay]).to eq(32_000)
      expect(score.level).to eq("役満")
    end

    it "multiple_yakuman なら役満の数だけ倍にする" do
      _winner_info, score = evaluate(Mahjong::Config::RuleConfig.new("multiple_yakuman" => true))

      expect(score.base_points).to eq(16_000)
      expect(score.payments[:ron_pay]).to eq(64_000)
      expect(score.level).to eq("2倍役満")
    end
  end
end
