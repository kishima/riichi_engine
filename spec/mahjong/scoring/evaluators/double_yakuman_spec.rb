require_relative "../../../spec_helper"

# double_yakuman（既定は偽）: 四暗刻単騎・国士無双十三面・純正九蓮宝燈・大四喜を
# ダブル役満（役満 2 つ分）で数える。
RSpec.describe Mahjong::Scoring::Evaluators::WinEvaluator do
  let(:double) { Mahjong::Config::RuleConfig.new("double_yakuman" => true) }
  let(:both) { Mahjong::Config::RuleConfig.new("double_yakuman" => true, "multiple_yakuman" => true) }
  let(:default_rule) { Mahjong::Config::RuleConfig.new }

  # 席 1（子）の門前の手。tsumo なら concealed に和了牌を含める。
  def evaluate(concealed, win, rule, tsumo: false, fuuros: [])
    state = Mahjong::State::RoundState.new
    state.hands = { 0 => Mahjong::State::Hand.new([]), 1 => Mahjong::State::Hand.new(tiles(concealed)),
                    2 => Mahjong::State::Hand.new([]), 3 => Mahjong::State::Hand.new([]) }
    state.fuuros[1] = fuuros
    state.menzen_flags[1] = fuuros.all?(&:ankan?)
    4.times { |s| state.first_turn_flags[s] = false }
    state.oya_seat = 0
    state.bakaze = "ton"
    state.wall = Mahjong::Tiles::Wall.new(tiles("1z 1z"))
    state.dora_hyouji = []
    state.uradora_hyouji = []
    state.phase = :round_end
    snapshot = Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze: "ton", oya_index: 0, honba: 0, kyoutaku: 0, jikaze: "nan")
    described_class.evaluate(state:, seat: 1, agari_type: tsumo ? :tsumo : :ron, agari_tile: Mahjong::Tiles::Tile.new(win),
                             rule:, extra_flags: {}, snapshot:)
  end

  def yaku_of(winner)
    winner[:yaku].map { |y| [y[:name], y[:han], y[:display]] }
  end

  {
    "四暗刻単騎" => ["2m 2m 2m 4p 4p 4p 6s 6s 6s 8m 8m 8m 9p", "9p", %w[suuankou 四暗刻単騎]],
    "国士無双十三面" => ["1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z", "5z", %w[kokushi_musou 国士無双十三面]],
    "純正九蓮宝燈" => ["1m 1m 1m 2m 3m 4m 5m 6m 7m 8m 9m 9m 9m", "5m", %w[chuuren_poutou 純正九蓮宝燈]]
  }.each do |label, (hand, win, (name, display))|
    it "#{label}はダブル役満（ロン 64000）" do
      winner, score = evaluate(hand, win, double)

      expect(yaku_of(winner)).to eq([[name, -2, display]])
      expect(score.payments[:ron_pay]).to eq(64_000)
      expect(score.level).to eq("2倍役満")
    end

    it "#{label}は double_yakuman が偽（既定）なら役満 1 つ" do
      winner, score = evaluate(hand, win, default_rule)

      expect(winner[:yaku].map { |y| y[:han] }).to eq([-1])
      expect(score.payments[:ron_pay]).to eq(32_000)
    end
  end

  let(:pon_east) do
    [Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("1z 1z 1z"), called_tile: Mahjong::Tiles::Tile.new("1z"), from_seat: 0)]
  end

  it "大四喜はダブル役満" do
    winner, score = evaluate("2z 2z 2z 3z 3z 3z 4z 4z 4z 9m", "9m", double, fuuros: pon_east)

    expect(yaku_of(winner)).to eq([["daisuushii", -2, "大四喜"]])
    expect(score.payments[:ron_pay]).to eq(64_000)
  end

  it "単騎でない四暗刻（双碰のツモ）、十三面でない国士、純正でない九蓮は役満 1 つ" do
    _w, suuankou = evaluate("2m 2m 2m 4p 4p 4p 6s 6s 6s 8m 8m 9p 9p 8m", "8m", double, tsumo: true)
    _w, kokushi = evaluate("1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 6z", "7z", double)
    _w, chuuren = evaluate("1m 1m 1m 2m 3m 4m 5m 6m 7m 8m 9m 9m 5m", "9m", double)

    expect([suuankou, kokushi, chuuren].map(&:base_points)).to eq([8000, 8000, 8000])
  end

  it "multiple_yakuman と合わせると足し合わせる（大四喜・字一色で 3 倍）" do
    _winner, score = evaluate("2z 2z 2z 3z 3z 3z 4z 4z 4z 5z", "5z", both, fuuros: pon_east)

    expect(score.base_points).to eq(24_000)
    expect(score.level).to eq("3倍役満")
  end

  it "multiple_yakuman が偽なら、いちばん大きい役満 1 つ（大四喜・字一色でダブル役満）" do
    _winner, score = evaluate("2z 2z 2z 3z 3z 3z 4z 4z 4z 5z", "5z", double, fuuros: pon_east)

    expect(score.base_points).to eq(16_000)
  end

  it "門前の大四喜・字一色・四暗刻単騎は multiple_yakuman と合わせて 5 倍" do
    winner, score = evaluate("1z 1z 1z 2z 2z 2z 3z 3z 3z 4z 4z 4z 5z", "5z", both)

    expect(winner[:yaku].map { |y| [y[:name], y[:han]] })
      .to contain_exactly(["daisuushii", -2], ["tsuuiisou", -1], ["suuankou", -2])
    expect(score.base_points).to eq(40_000)
  end
end
