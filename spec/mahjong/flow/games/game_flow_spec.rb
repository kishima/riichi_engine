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
    it "ダブロンに親が入っていれば連荘し、本場を積む" do
      snapshot = build_progress_snapshot(honba: 1, oya_index: 0)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron_agari, winners: [{ seat: 3 }, { seat: 0 }], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result.renchan).to be true
      expect(result.next_oya_index).to eq(0)
      expect(result.next_honba).to eq(2)
    end

    it "親の入らないダブロンは親が流れる" do
      snapshot = build_progress_snapshot(honba: 1, oya_index: 0)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :ron_agari, winners: [{ seat: 1 }, { seat: 3 }], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result.renchan).to be false
      expect(result.next_oya_index).to eq(1)
      expect(result.next_honba).to eq(0)
    end

    it "三家和は途中流局として連荘し、本場を積む" do
      snapshot = build_progress_snapshot(honba: 0, oya_index: 2, kyoku: 3)
      info = Mahjong::Results::RoundEndInfo.new(result_type: :sanchahou, winners: [], tenpai_seats: [])

      result = described_class.judge_next(progress_snapshot: snapshot, round_end_info: info, rule:)

      expect(result.renchan).to be true
      expect(result.next_oya_index).to eq(2)
      expect(result.next_kyoku).to eq(3)
      expect(result.next_honba).to eq(1)
    end

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
