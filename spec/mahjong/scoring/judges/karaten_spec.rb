require_relative "../../../spec_helper"

# 形式聴牌とカラテン。見えている枚数は聴牌の判定に入らない。手の内に 4 枚ある牌の単騎待ちだけは、待ちの牌が
# 手の中にしか無い（和了る 5 枚目が無い）ので待ちに数えない。ポンした牌の 4 枚目（手の内は 1 枚）の単騎は、
# 4 枚とも見えていても聴牌に数える。
RSpec.describe Mahjong::Scoring::Judges::MachiJudge do
  def round_state(hands, fuuros = {})
    state = Mahjong::State::RoundState.new
    hands.each { |seat, str| state.hands[seat] = Mahjong::State::Hand.new(tiles(str)) }
    fuuros.each { |seat, list| state.fuuros[seat] = list }
    state
  end

  def pon(str, from)
    t = tiles(str)
    Mahjong::State::Fuuro.new(type: :pon, tiles: t, called_tile: t.first, from_seat: from)
  end

  it "ポンした牌の 4 枚目の単騎は聴牌（流局の聴牌の席に入る）" do
    state = round_state({ 0 => "1m 2m 3m 4m 5m 6m 7p 8p 9p 1z", 1 => "1m 3m 5m 7m 9m 1p 3p 5p 7p 9p 2z 3z 4z",
                          2 => "1s 3s 5s 7s 9s 1p 3p 5p 7p 9p 2z 3z 4z", 3 => "1s 3s 5s 7s 9s 1m 3m 5m 7m 9m 2z 3z 4z" },
                        { 0 => [pon("1z 1z 1z", 3)] })

    expect(described_class.machi_tile_indices(state.hands[0].to_34)).to eq([27])
    expect(RiichiEngine::API.tenpai_seats(state)).to eq([0])
  end

  it "手の内に 4 枚ある牌の単騎待ちは聴牌でない" do
    hand = tiles_34("9s 9s 9s 9s 2s 3s 4s 1p 2p 3p 4p 5p 6p")

    expect(described_class.find_machi(hand)).to eq([])
    expect(described_class.tenpai?(hand)).to be false
  end

end
