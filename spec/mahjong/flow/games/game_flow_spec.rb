require_relative "../../../spec_helper"

RSpec.describe Mahjong::Flow::Games::GameFlow do
  let(:rule) { Mahjong::Config::RuleConfig.new }

  def build_progress_snapshot(bakaze: "ton", kyoku: 1, honba: 0, kyoutaku: 0, oya_index: 0, scores: [25_000, 25_000, 25_000, 25_000])
    Mahjong::Snapshots::GameProgressSnapshot.new(
      bakaze:,
      kyoku:,
      honba:,
      kyoutaku:,
      oya_index:,
      scores: scores.each_with_index.to_h { |score, seat| [seat, score] }
    )
  end

  def build_final_result_snapshot(scores: [25_000, 25_000, 25_000, 25_000])
    Mahjong::Snapshots::FinalResultSnapshot.new(
      scores: scores.each_with_index.to_h { |score, seat| [seat, score] },
      players_by_seat: 4.times.to_h { |seat| [seat, { player_id: seat + 1, name: "Player #{seat + 1}" }] }
    )
  end

  describe ".judge_next" do
    it "子の和了で親が流れる" do
      snapshot = build_progress_snapshot
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron, winners: [{ seat: 1 }], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result).to be_next_round
      expect(result.next_oya_index).to eq(1)
      expect(result.next_kyoku).to eq(2)
      expect(result.next_honba).to eq(0)
      expect(result.renchan).to be false
    end

    it "親の和了で連荘する" do
      snapshot = build_progress_snapshot(honba: 1, oya_index: 0)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :tsumo, winners: [{ seat: 0 }], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result).to be_next_round
      expect(result.next_oya_index).to eq(0)
      expect(result.next_kyoku).to eq(1)
      expect(result.next_honba).to eq(2)
      expect(result.renchan).to be true
    end

    it "流局で親テンパイなら連荘" do
      snapshot = build_progress_snapshot(honba: 2)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ryuukyoku, winners: [], tenpai_seats: [0, 2])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result).to be_next_round
      expect(result.renchan).to be true
      expect(result.next_honba).to eq(3)
    end

    it "流局で親ノーテンなら親が流れるが本場は増える" do
      snapshot = build_progress_snapshot(honba: 2)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ryuukyoku, winners: [], tenpai_seats: [1, 2])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result).to be_next_round
      expect(result.renchan).to be false
      expect(result.next_oya_index).to eq(1)
      expect(result.next_honba).to eq(3)
    end

    it "東4局終了で東風戦はゲーム終了" do
      snapshot = build_progress_snapshot(bakaze: "ton", kyoku: 4)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron, winners: [{ seat: 1 }], tenpai_seats: [])
      tonpuu_rule = Mahjong::Config::RuleConfig.new("game_type" => "tonpuusen")

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule: tonpuu_rule)

      expect(result).to be_game_end
      expect(result.reason).to eq(:normal_end)
    end

    it "README の game_type \"tonpuu\" でも東4局終了でゲーム終了" do
      snapshot = build_progress_snapshot(bakaze: "ton", kyoku: 4)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron, winners: [{ seat: 1 }], tenpai_seats: [])
      tonpuu_rule = Mahjong::Config::RuleConfig.new("game_type" => "tonpuu")

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule: tonpuu_rule)

      expect(result).to be_game_end
      expect(result.reason).to eq(:normal_end)
    end

    it "東風戦（\"tonpuu\"）の東4局で親がトップで和了ればゲーム終了" do
      snapshot = build_progress_snapshot(bakaze: "ton", kyoku: 4, oya_index: 3,
                                         scores: [20_000, 20_000, 20_000, 40_000])
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron, winners: [{ seat: 3 }], tenpai_seats: [])
      tonpuu_rule = Mahjong::Config::RuleConfig.new("game_type" => "tonpuu")

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule: tonpuu_rule)

      expect(result).to be_game_end
      expect(result.reason).to eq(:all_last_oya_agari)
    end

    describe "アガリ止め・テンパイ止め" do
      let(:all_last) { build_progress_snapshot(bakaze: "nan", kyoku: 4, oya_index: 3, scores: [20_000, 20_000, 20_000, 40_000]) }
      let(:oya_win) { Mahjong::Results::RoundEndInfo.new(result_type: :ron, winners: [{ seat: 3 }], tenpai_seats: []) }
      let(:oya_tenpai) { Mahjong::Results::RoundEndInfo.new(result_type: :ryuukyoku, winners: [], tenpai_seats: [3]) }

      it "既定（agari_yame あり・tenpai_yame なし）: 首位の親の和了で終わり、テンパイでは続く" do
        expect(described_class.judge_next(progress_snapshot: all_last, round_end_info: oya_win, rule:).reason).to eq(:all_last_oya_agari)

        result = described_class.judge_next(progress_snapshot: all_last, round_end_info: oya_tenpai, rule:)
        expect(result).to be_next_round
        expect(result.renchan).to be(true)
      end

      it "agari_yame が偽なら首位の親が和了っても続く" do
        no_stop = Mahjong::Config::RuleConfig.new("agari_yame" => false)
        result = described_class.judge_next(progress_snapshot: all_last, round_end_info: oya_win, rule: no_stop)

        expect(result).to be_next_round
        expect(result.next_honba).to eq(1)
      end

      it "tenpai_yame なら首位の親のテンパイ流局で終わる" do
        stop = Mahjong::Config::RuleConfig.new("tenpai_yame" => true)
        result = described_class.judge_next(progress_snapshot: all_last, round_end_info: oya_tenpai, rule: stop)

        expect(result).to be_game_end
        expect(result.reason).to eq(:all_last_oya_tenpai)
      end

      it "tenpai_yame でも親が首位でなければ続く" do
        stop = Mahjong::Config::RuleConfig.new("tenpai_yame" => true)
        behind = build_progress_snapshot(bakaze: "nan", kyoku: 4, oya_index: 3, scores: [40_000, 20_000, 20_000, 20_000])

        expect(described_class.judge_next(progress_snapshot: behind, round_end_info: oya_tenpai, rule: stop)).to be_next_round
      end
    end

    it "東4局の子和了で半荘は南1局へ進む" do
      snapshot = build_progress_snapshot(bakaze: "ton", kyoku: 4)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron, winners: [{ seat: 1 }], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result).to be_next_round
      expect(result.next_bakaze).to eq("nan")
      expect(result.next_kyoku).to eq(1)
      expect(result.next_oya_index).to eq(1)
    end

    it "南4局終了で半荘はゲーム終了" do
      snapshot = build_progress_snapshot(bakaze: "nan", kyoku: 4)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron, winners: [{ seat: 1 }], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result).to be_game_end
    end

    it "トビで即ゲーム終了" do
      snapshot = build_progress_snapshot(scores: [30_000, -100, 20_000, 50_100])
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron, winners: [{ seat: 0 }], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result).to be_game_end
      expect(result.reason).to eq(:tobi)
    end

    it "西入条件を満たす場合は続行する" do
      snapshot = build_progress_snapshot(bakaze: "nan", kyoku: 4, scores: [29_000, 28_000, 22_000, 21_000])
      west_rule = Mahjong::Config::RuleConfig.new("nishi_iri" => true)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron, winners: [{ seat: 1 }], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule: west_rule)

      expect(result).to be_next_round
      expect(result.next_bakaze).to eq("sha")
    end

    it "オーラス親和了トップなら終了する" do
      snapshot = build_progress_snapshot(bakaze: "nan", kyoku: 4, scores: [35_000, 20_000, 25_000, 20_000])
      info = Mahjong::Results::RoundEndInfo.new(result_type: :tsumo, winners: [{ seat: 0 }], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result).to be_game_end
      expect(result.reason).to eq(:all_last_oya_agari)
    end

    it "RoundFlow 互換の Hash round_end_info でも連荘判定できる" do
      snapshot = build_progress_snapshot(honba: 1, oya_index: 0)
      info = { type: :tsumo_agari, winner_seat: 0, loser_seat: nil }

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result).to be_next_round
      expect(result.renchan).to be true
      expect(result.next_oya_index).to eq(0)
      expect(result.next_kyoku).to eq(1)
      expect(result.next_honba).to eq(2)
    end
  end

  describe "南入・サドンデス（nan_iri・sudden_death）" do
    def info(type, winners: [], tenpai: [])
      Mahjong::Results::RoundEndInfo.new(result_type: type, winners: winners.map { |s| { seat: s } }, tenpai_seats: tenpai)
    end

    def judge(rule, info, **snap)
      described_class.judge_next(progress_snapshot: build_progress_snapshot(**snap), round_end_info: info, rule:)
    end

    let(:tonpuu) { Mahjong::Config::RuleConfig.new("game_type" => "tonpuu", "nan_iri" => true) }
    let(:tonpuu_sd) { Mahjong::Config::RuleConfig.new("game_type" => "tonpuu", "nan_iri" => true, "sudden_death" => true) }
    let(:hanchan_sd) { Mahjong::Config::RuleConfig.new("nishi_iri" => true, "sudden_death" => true) }
    let(:low) { [26_000, 25_000, 25_000, 24_000] }

    it "東風戦の東4局の後、誰も 30000 に届いていなければ nan_iri で南場へ（既定は終わる）" do
      flow = judge(tonpuu, info(:ron, winners: [1]), bakaze: "ton", kyoku: 4, oya_index: 3, scores: low)
      expect([flow.action, flow.next_bakaze, flow.next_kyoku]).to eq([:next_round, "nan", 1])

      flow = judge(Mahjong::Config::RuleConfig.new("game_type" => "tonpuu"), info(:ron, winners: [1]), bakaze: "ton", kyoku: 4, oya_index: 3, scores: low)
      expect(flow.action).to eq(:game_end)
    end

    it "東風戦の東4局の後、30000 に届いた人がいれば南場に入らない" do
      flow = judge(tonpuu, info(:ron, winners: [1]), bakaze: "ton", kyoku: 4, oya_index: 3, scores: [20_000, 31_000, 25_000, 24_000])

      expect([flow.action, flow.reason]).to eq(%i[game_end normal_end])
    end

    it "サドンデスなしの南場は、親が流れるときに 30000 以上がいれば終わる（連荘なら続く）" do
      flow = judge(tonpuu, info(:ron, winners: [0]), bakaze: "nan", kyoku: 1, oya_index: 0, scores: [31_000, 23_000, 23_000, 23_000])
      expect(flow.action).to eq(:next_round)

      flow = judge(tonpuu, info(:ron, winners: [1]), bakaze: "nan", kyoku: 1, oya_index: 0, scores: [19_000, 31_000, 25_000, 25_000])
      expect([flow.action, flow.reason]).to eq(%i[game_end normal_end])
    end

    it "サドンデスなら、親の連荘でも 30000 以上になった局で終わる" do
      flow = judge(tonpuu_sd, info(:ron, winners: [0]), bakaze: "nan", kyoku: 1, oya_index: 0, scores: [31_000, 23_000, 23_000, 23_000])
      expect([flow.action, flow.reason]).to eq(%i[game_end sudden_death])

      flow = judge(hanchan_sd, info(:ryuukyoku, tenpai: [0, 2]), bakaze: "sha", kyoku: 2, oya_index: 1, scores: [20_000, 25_500, 30_500, 24_000])
      expect([flow.action, flow.reason]).to eq(%i[game_end sudden_death])
    end

    it "サドンデスでも、親を含む複数人のロンで親が連荘するときは続ける" do
      flow = judge(hanchan_sd, info(:ron, winners: [1, 2]), bakaze: "sha", kyoku: 2, oya_index: 1, scores: [10_000, 29_000, 32_000, 29_000])

      expect([flow.action, flow.renchan, flow.next_kyoku]).to eq([:next_round, true, 2])
    end

    it "サドンデスの延長は 1 つの場だけ: 東風戦は南4局、半荘は西4局の後に終わる" do
      flow = judge(tonpuu_sd, info(:ron, winners: [1]), bakaze: "nan", kyoku: 4, oya_index: 3, scores: low)
      expect([flow.action, flow.reason]).to eq(%i[game_end normal_end])

      flow = judge(hanchan_sd, info(:ron, winners: [1]), bakaze: "sha", kyoku: 4, oya_index: 3, scores: low)
      expect([flow.action, flow.reason]).to eq(%i[game_end normal_end])
    end

    it "sudden_death なしの西4局の後は西1局に戻る（0.1.0 と同じ）" do
      flow = judge(Mahjong::Config::RuleConfig.new("nishi_iri" => true), info(:ron, winners: [1]), bakaze: "sha", kyoku: 4, oya_index: 3, scores: low)

      expect([flow.action, flow.next_bakaze, flow.next_kyoku]).to eq([:next_round, "sha", 1])
    end

    it "延長戦があるルールでは、アガリ止めは親が 30000 以上のときだけ" do
      flow = judge(Mahjong::Config::RuleConfig.new("nishi_iri" => true), info(:ron, winners: [3]), bakaze: "nan", kyoku: 4, oya_index: 3, scores: [20_000, 21_000, 29_000, 30_000])
      expect([flow.action, flow.reason]).to eq(%i[game_end all_last_oya_agari])

      flow = judge(Mahjong::Config::RuleConfig.new("nishi_iri" => true), info(:ron, winners: [3]), bakaze: "nan", kyoku: 4, oya_index: 3, scores: [20_000, 21_000, 27_000, 29_000])
      expect([flow.action, flow.renchan]).to eq([:next_round, true])

      flow = judge(rule, info(:ron, winners: [3]), bakaze: "nan", kyoku: 4, oya_index: 3, scores: [20_000, 21_000, 27_000, 29_000])
      expect(flow.reason).to eq(:all_last_oya_agari)
    end

    it "サドンデスの延長戦の 4 局目は、首位の親の複数人ロンでもアガリ止め" do
      flow = judge(hanchan_sd, info(:ron, winners: [3, 1]), bakaze: "sha", kyoku: 4, oya_index: 3, scores: [10_000, 29_000, 29_000, 32_000])

      expect([flow.action, flow.reason]).to eq(%i[game_end all_last_oya_agari])
    end
  end

  describe ".calculate_final_result" do
    it "順位とウマオカを反映した最終結果を返す" do
      snapshot = build_final_result_snapshot(scores: [35_000, 28_000, 22_000, 15_000])

      results = described_class.calculate_final_result(final_result_snapshot: snapshot, rule:)

      expect(results.map(&:seat)).to eq([0, 1, 2, 3])
      expect(results.map(&:rank)).to eq([1, 2, 3, 4])
      expect(results.first.point).to eq(45.0)
      expect(results.last.point).to eq(-35.0)
    end

    it "同点時は席順で順位が決まる" do
      snapshot = build_final_result_snapshot(scores: [25_000, 25_000, 20_000, 30_000])

      results = described_class.calculate_final_result(final_result_snapshot: snapshot, rule:)

      expect(results.map(&:seat)).to eq([3, 0, 1, 2])
      expect(results.find { |r| r.seat == 0 }.rank).to eq(2)
      expect(results.find { |r| r.seat == 1 }.rank).to eq(3)
    end
  end

  describe ".calculate_tenpai_payments" do
    it "テンパイ1人: +3000 / -1000x3" do
      expect(described_class.calculate_tenpai_payments([0])).to eq({ 0 => 3000, 1 => -1000, 2 => -1000, 3 => -1000 })
    end

    it "テンパイ2人: +1500x2 / -1500x2" do
      expect(described_class.calculate_tenpai_payments([0, 2])).to eq({ 0 => 1500, 1 => -1500, 2 => 1500, 3 => -1500 })
    end

    it "テンパイ3人: +1000x3 / -3000" do
      expect(described_class.calculate_tenpai_payments([0, 1, 2])).to eq({ 0 => 1000, 1 => 1000, 2 => 1000, 3 => -3000 })
    end

    it "テンパイ0人/4人は変動なし" do
      expect(described_class.calculate_tenpai_payments([])).to eq({ 0 => 0, 1 => 0, 2 => 0, 3 => 0 })
      expect(described_class.calculate_tenpai_payments([0, 1, 2, 3])).to eq({ 0 => 0, 1 => 0, 2 => 0, 3 => 0 })
    end
  end
end
