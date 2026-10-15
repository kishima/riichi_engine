require_relative "../../../spec_helper"

# 途中流局: 四風連打（suufon_renda）・四槓散了（suukaikan）・四家立直（suucha_riichi）。
# どれも既定は無効（0.1.0 と同じく局は続く）。
RSpec.describe Mahjong::Flow::Rounds::RoundFlow do
  let(:all_on) { Mahjong::Config::RuleConfig.new("suufon_renda" => true, "suukaikan" => true, "suucha_riichi" => true) }
  let(:default_rule) { Mahjong::Config::RuleConfig.new }
  let(:snapshot) do
    Mahjong::Snapshots::GameSetupSnapshot.new(
      bakaze: "ton", kyoku: 1, honba: 0, kyoutaku: 0, oya_index: 0,
      scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
    )
  end

  # 誰も鳴けもロンもできない手（1z は各 1 枚）
  let(:quiet_hands) do
    {
      0 => "1m 4m 7m 1p 4p 7p 1s 4s 7s 1z 3z 5z 6z",
      1 => "2m 5m 8m 2p 5p 8p 2s 5s 8s 1z 3z 5z 7z",
      2 => "3m 6m 9m 3p 6p 9p 3s 6s 9s 1z 3z 6z 7z",
      3 => "1m 5m 9m 1p 5p 9p 1s 5s 9s 1z 4z 6z 7z"
    }
  end

  def round(hands:, draws:)
    state = described_class.setup(game_snapshot: snapshot, rule: default_rule, seed: "abortive")
    hands.each { |seat, str| state.hands[seat] = Mahjong::State::Hand.new(tiles(str)) }
    state.wall = Mahjong::Tiles::Wall.new(tiles(draws) + state.wall.tiles.drop(tiles(draws).size))
    state
  end

  def act(state, action, rule)
    described_class.apply_action(state:, action:, rule:)
  end

  # 各席が tsumo して tile を切る（鳴きは全員見送る）
  def go_around(state, discards, rule)
    result = nil
    discards.each do |tile|
      act(state, { type: :tsumo }, rule)
      seat = state.current_seat
      result = act(state, { type: :dahai, seat:, tile: }, rule)
      state.pending_actions.keys.each { |s| result = act(state, { type: :skip, seat: s }, rule) } if state.phase == :naki_wait
      break if state.phase == :round_end
    end
    result
  end

  describe "四風連打" do
    it "鳴きの無い第一巡で 4 人が同じ風牌を切ると、4 人目の打牌で流局" do
      state = round(hands: quiet_hands, draws: "2m 2m 2m 2m")
      result = go_around(state, %w[1z 1z 1z 1z], all_on)

      expect(result).to be_round_end
      expect(result.round_end_info[:result_type]).to eq(:suufon_renda)
      expect(result.round_end_info[:draw_reason]).to eq(:suufon_renda)
    end

    it "既定のルールでは流局しない" do
      state = round(hands: quiet_hands, draws: "2m 2m 2m 2m")
      go_around(state, %w[1z 1z 1z 1z], default_rule)

      expect(state.phase).to eq(:tsumo)
    end

    it "風牌がそろわなければ流局しない" do
      state = round(hands: quiet_hands, draws: "2m 2m 2m 2m")
      go_around(state, %w[1z 1z 1z 4z], all_on)

      expect(state.phase).to eq(:tsumo)
    end

    it "三元牌がそろっても四風連打ではない" do
      state = round(hands: quiet_hands.merge(0 => "1m 4m 7m 1p 4p 7p 1s 4s 7s 1z 3z 5z 7z"), draws: "2m 2m 2m 2m")
      go_around(state, %w[7z 7z 7z 7z], all_on)

      expect(state.phase).to eq(:tsumo)
    end
  end

  describe "四家立直" do
    it "4 人目のリーチの打牌がロンされなければ流局（供託は場に残る）" do
      state = round(hands: quiet_hands, draws: "2m")
      [0, 1, 2].each { |seat| state.riichi_flags[seat] = true }
      state.current_seat = 3
      state.hands[3] = Mahjong::State::Hand.new(tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s"))
      act(state, { type: :tsumo }, all_on)
      result = act(state, { type: :riichi, seat: 3, tile: "2m" }, all_on)

      expect(result).to be_round_end
      expect(result.round_end_info[:result_type]).to eq(:suucha_riichi)
      expect(state.kyoutaku).to eq(1)
    end

    it "4 人目のリーチの打牌にロンできる席があれば、ロンだけが残り、見送ると流局" do
      state = round(hands: quiet_hands, draws: "3s")
      [0, 1, 2].each { |seat| state.riichi_flags[seat] = true }
      state.hands[0] = Mahjong::State::Hand.new(tiles("1m 2m 3m 4p 5p 6p 7p 8p 9p 9m 9m 2s 4s"))
      state.current_seat = 3
      state.hands[3] = Mahjong::State::Hand.new(tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s"))
      act(state, { type: :tsumo }, all_on)
      act(state, { type: :riichi, seat: 3, tile: "3s" }, all_on)

      expect(state.phase).to eq(:naki_wait)
      expect(state.pending_actions).to eq(0 => [{ type: :ron_agari }])
      result = act(state, { type: :skip, seat: 0 }, all_on)
      expect(result.round_end_info[:result_type]).to eq(:suucha_riichi)
    end

    it "既定のルールでは流局しない" do
      state = round(hands: quiet_hands, draws: "2m")
      [0, 1, 2].each { |seat| state.riichi_flags[seat] = true }
      state.current_seat = 3
      state.hands[3] = Mahjong::State::Hand.new(tiles("1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s"))
      act(state, { type: :tsumo }, default_rule)
      act(state, { type: :riichi, seat: 3, tile: "2m" }, default_rule)

      expect(state.phase).to eq(:tsumo)
    end
  end

  describe "四槓散了" do
    it "2 人以上で槓が 4 つになった後の打牌が通ると流局" do
      state = round(hands: quiet_hands, draws: "2m")
      state.kan_count = 4
      state.kan_by_player = { 0 => 3, 1 => 1, 2 => 0, 3 => 0 }
      result = go_around(state, %w[2m], all_on)

      expect(result.round_end_info[:result_type]).to eq(:suukaikan)
    end

    it "1 人で 4 つ槓した後は流局しない（四槓子の待ち）" do
      state = round(hands: quiet_hands, draws: "2m")
      state.kan_count = 4
      state.kan_by_player = { 0 => 4, 1 => 0, 2 => 0, 3 => 0 }
      go_around(state, %w[2m], all_on)

      expect(state.phase).to eq(:tsumo)
    end
  end

  describe "次局（GameFlow）" do
    %i[suufon_renda suukaikan suucha_riichi].each do |kind|
      it "#{kind} は親の連荘で本場が 1 つ増える" do
        progress = Mahjong::Snapshots::GameProgressSnapshot.new(
          bakaze: "ton", kyoku: 2, honba: 1, kyoutaku: 4, oya_index: 1,
          scores: { 0 => 21_000, 1 => 24_000, 2 => 24_000, 3 => 27_000 }
        )
        info = Mahjong::Results::RoundEndInfo.new(result_type: kind, winners: [], tenpai_seats: [])
        result = Mahjong::Flow::Games::GameFlow.judge_next(progress_snapshot: progress, round_end_info: info, rule: all_on)

        expect(result).to be_next_round
        expect(result.renchan).to be(true)
        expect(result.next_oya_index).to eq(1)
        expect(result.next_honba).to eq(2)
      end
    end
  end
end
