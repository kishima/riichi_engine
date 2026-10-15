require_relative "../../../spec_helper"

# 流し満貫（nagashi_mangan、既定は無効）: 荒牌流局で、河が么九牌だけで、どれも鳴かれて
# いない席。round_end_info の nagashi_seats に入り、支払いは
# calculate_nagashi_mangan_payments（満貫のツモと同じ額、本場なし）。
RSpec.describe "流し満貫" do
  let(:rule) { Mahjong::Config::RuleConfig.new("nagashi_mangan" => true) }
  let(:default_rule) { Mahjong::Config::RuleConfig.new }
  let(:snapshot) do
    Mahjong::Snapshots::GameSetupSnapshot.new(
      bakaze: "ton", kyoku: 1, honba: 0, kyoutaku: 0, oya_index: 0,
      scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
    )
  end

  # 牌山の残りが 1 枚で、席 3 が最後の牌を引いて切る局。河は kawas の通り。
  def last_turn(rule, kawas)
    state = RiichiEngine::API.setup_round(game_snapshot: snapshot, rule:, seed: "nagashi")
    state.hands = {
      0 => Mahjong::State::Hand.new(tiles("1m 4m 7m 1p 4p 7p 1s 4s 7s 2z 3z 4z 6z")),
      1 => Mahjong::State::Hand.new(tiles("2m 5m 8m 2p 5p 8p 2s 5s 8s 1z 3z 5z 7z")),
      2 => Mahjong::State::Hand.new(tiles("3m 6m 9m 3p 6p 9p 3s 6s 9s 1z 3z 6z 7z")),
      3 => Mahjong::State::Hand.new(tiles("1m 5m 9m 1p 5p 9p 1s 5s 9s 1z 4z 6z 7z"))
    }
    kawas.each do |seat, list|
      kawa = Mahjong::State::Kawa.new
      list.split.each do |t|
        kawa.add(t.delete("*"))
        kawa.mark_last_called! if t.end_with?("*")
      end
      state.kawas[seat] = kawa
    end
    state.wall = Mahjong::Tiles::Wall.new(tiles("9m"))
    state.current_seat = 3
    state
  end

  def finish(state, rule)
    RiichiEngine::API.apply_round_action(state:, action: { type: :tsumo }, rule:)
    result = RiichiEngine::API.apply_round_action(state:, action: { type: :dahai, seat: 3, tile: "9m" }, rule:)
    state.pending_actions.keys.each do |seat|
      result = RiichiEngine::API.apply_round_action(state:, action: { type: :skip, seat: seat }, rule:)
    end
    result
  end

  let(:kawas) do
    {
      0 => "1m 9p 1z 7z 9s",       # 么九牌だけ: 成立
      1 => "1m 9p 2m",             # 2m がある: 不成立
      2 => "9m 1s* 5z",            # 1s が鳴かれた: 不成立
      3 => "1z 9s 1p"              # 最後に 9m を切る: 成立
    }
  end

  it "荒牌流局で、河が么九牌だけで鳴かれていない席が nagashi_seats に入る" do
    result = finish(last_turn(rule, kawas), rule)

    expect(result.round_end_info[:result_type]).to eq(:ryuukyoku)
    expect(result.round_end_info[:nagashi_seats]).to eq([0, 3])
  end

  it "既定のルールでは nagashi_seats を出さない（0.1.0 と同じ）" do
    result = finish(last_turn(default_rule, kawas), default_rule)

    expect(result.round_end_info[:result_type]).to eq(:ryuukyoku)
    expect(result.round_end_info).not_to have_key(:nagashi_seats)
  end

  describe "RiichiEngine::API.calculate_nagashi_mangan_payments" do
    it "子は 2000/4000、親は 4000 オールを受け取る（本場なし）" do
      expect(RiichiEngine::API.calculate_nagashi_mangan_payments([2], oya_seat: 0))
        .to eq(0 => -4000, 1 => -2000, 2 => 8000, 3 => -2000)
      expect(RiichiEngine::API.calculate_nagashi_mangan_payments([0], oya_seat: 0))
        .to eq(0 => 12_000, 1 => -4000, 2 => -4000, 3 => -4000)
    end

    it "2 人が成立すればそれぞれの支払いを足す" do
      expect(RiichiEngine::API.calculate_nagashi_mangan_payments([0, 3], oya_seat: 0))
        .to eq(0 => 12_000 - 4000, 1 => -6000, 2 => -6000, 3 => 8000 - 4000)
    end

    it "成立した席が無ければ動かない" do
      expect(RiichiEngine::API.calculate_nagashi_mangan_payments([], oya_seat: 1)).to eq(0 => 0, 1 => 0, 2 => 0, 3 => 0)
    end
  end
end
