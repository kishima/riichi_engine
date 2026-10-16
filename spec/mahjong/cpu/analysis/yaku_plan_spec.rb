require_relative "../../../spec_helper"

RSpec.describe Mahjong::Cpu::Analysis::YakuPlan do
  def pon(str) = Mahjong::State::Fuuro.new(type: :pon, tiles: tiles(str))
  def chi(str) = Mahjong::State::Fuuro.new(type: :chi, tiles: tiles(str))
  def t34(str) = Mahjong::Tiles::TileSet.to_34(tiles(str))

  let(:winds) { { jikaze: "nan", bakaze: "ton" } }

  it "副露から残っている筋を返す" do
    expect(described_class.plans([pon("5m 5m 5m")], **winds)).to eq(%i[tanyao honitsu_m toitoi])
    expect(described_class.plans([chi("1p 2p 3p")], **winds)).to eq(%i[honitsu_p])
    expect(described_class.plans([pon("2z 2z 2z")], **winds)).to eq(%i[yakuhai honitsu_m honitsu_p honitsu_s toitoi])
    expect(described_class.plans([pon("3z 3z 3z"), chi("1p 2p 3p"), chi("4s 5s 6s")], **winds)).to eq([])
  end

  it "喰い断が無ければ断么九の筋は無い" do
    expect(described_class.plans([chi("2p 3p 4p")], **winds, kuitan: false)).to eq(%i[honitsu_p])
  end

  it "筋ごとの向聴数はその筋で使えない牌を除いて数える" do
    hand = t34("2p 3p 4p 6s 7s 3m 4m 9p 9p 8s")
    expect(described_class.shanten(:yakuhai, hand, 1)).to eq(0)
    expect(described_class.shanten(:tanyao, hand, 1)).to eq(1)
    expect(described_class.shanten(:honitsu_p, hand, 1)).to eq(3)
  end

  it "対々和の向聴数は刻子と対子で数える" do
    expect(described_class.shanten(:toitoi, t34("1m 1m 1m 4p 4p 7s 7s 9s 9s 3z"), 1)).to eq(1)
    expect(described_class.shanten(:toitoi, t34("1m 1m 1m 4p 4p 4p 7s 7s 7s 3z"), 1)).to eq(0)
    expect(described_class.shanten(:toitoi, t34("1m 1m 1m 4p 4p 4p 7s 7s 9s 9s"), 1)).to eq(0)
  end
end
