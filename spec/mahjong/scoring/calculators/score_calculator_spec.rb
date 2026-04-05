require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Calculators::ScoreCalculator do
  describe ".calculate" do
    context "子のロン" do
      [
        { fu: 30, han: 1, ron: 1000 },
        { fu: 40, han: 1, ron: 1300 },
        { fu: 60, han: 2, ron: 3900 },
        { fu: 25, han: 3, ron: 3200 },
        { fu: 30, han: 4, ron: 7700 }
      ].each do |row|
        it "#{row[:fu]}符#{row[:han]}翻 = #{row[:ron]}点" do
          result = described_class.calculate(fu: row[:fu], han: row[:han], is_oya: false, agari_type: :ron)

          expect(result.payments[:ron_pay]).to eq(row[:ron])
        end
      end
    end

    context "親のロン" do
      [
        { fu: 30, han: 1, ron: 1500 },
        { fu: 40, han: 2, ron: 3900 },
        { fu: 60, han: 2, ron: 5800 },
        { fu: 30, han: 3, ron: 5800 },
        { fu: 30, han: 4, ron: 11600 }
      ].each do |row|
        it "#{row[:fu]}符#{row[:han]}翻 = #{row[:ron]}点" do
          result = described_class.calculate(fu: row[:fu], han: row[:han], is_oya: true, agari_type: :ron)

          expect(result.payments[:ron_pay]).to eq(row[:ron])
        end
      end
    end

    context "子のツモ" do
      [
        { fu: 30, han: 1, ko: 300, oya: 500 },
        { fu: 40, han: 2, ko: 700, oya: 1300 },
        { fu: 25, han: 3, ko: 800, oya: 1600 },
        { fu: 30, han: 4, ko: 2000, oya: 3900 }
      ].each do |row|
        it "#{row[:fu]}符#{row[:han]}翻 = #{row[:ko]}/#{row[:oya]}点" do
          result = described_class.calculate(fu: row[:fu], han: row[:han], is_oya: false, agari_type: :tsumo)

          expect(result.payments[:ko_pays]).to eq(row[:ko])
          expect(result.payments[:oya_pays]).to eq(row[:oya])
        end
      end
    end

    context "親のツモ" do
      [
        { fu: 30, han: 1, ko: 500 },
        { fu: 40, han: 2, ko: 1300 },
        { fu: 25, han: 3, ko: 1600 },
        { fu: 30, han: 4, ko: 3900 }
      ].each do |row|
        it "#{row[:fu]}符#{row[:han]}翻 = #{row[:ko]}点オール" do
          result = described_class.calculate(fu: row[:fu], han: row[:han], is_oya: true, agari_type: :tsumo)

          expect(result.payments[:ko_pays]).to eq(row[:ko])
        end
      end
    end

    context "満貫以上" do
      it "満貫子ロン = 8000点" do
        result = described_class.calculate(fu: 30, han: 5, is_oya: false, agari_type: :ron)
        expect(result.payments[:ron_pay]).to eq(8000)
        expect(result.level).to eq("満貫")
      end

      it "跳満子ツモ = 3000/6000" do
        result = described_class.calculate(fu: 40, han: 6, is_oya: false, agari_type: :tsumo)
        expect(result.payments[:ko_pays]).to eq(3000)
        expect(result.payments[:oya_pays]).to eq(6000)
        expect(result.level).to eq("跳満")
      end

      it "倍満親ロン = 24000点" do
        result = described_class.calculate(fu: 40, han: 8, is_oya: true, agari_type: :ron)
        expect(result.payments[:ron_pay]).to eq(24000)
        expect(result.level).to eq("倍満")
      end

      it "三倍満親ツモ = 12000オール" do
        result = described_class.calculate(fu: 40, han: 11, is_oya: true, agari_type: :tsumo)
        expect(result.payments[:ko_pays]).to eq(12000)
        expect(result.level).to eq("三倍満")
      end

      it "数え役満子ロン = 32000点" do
        result = described_class.calculate(fu: 30, han: 13, is_oya: false, agari_type: :ron)
        expect(result.payments[:ron_pay]).to eq(32000)
        expect(result.level).to eq("数え役満")
      end

      it "役満子ロン = 32000点" do
        result = described_class.calculate(fu: 0, han: 0, is_oya: false, agari_type: :ron, is_yakuman: true)
        expect(result.payments[:ron_pay]).to eq(32000)
        expect(result.level).to eq("役満")
      end
    end

    context "ルール差分" do
      it "切り上げ満貫ルールを適用する" do
        result = described_class.calculate(
          fu: 30, han: 4, is_oya: false, agari_type: :ron,
          rule: Mahjong::Config::RuleConfig.new("kiriage_mangan" => true)
        )

        expect(result.payments[:ron_pay]).to eq(8000)
        expect(result.level).to eq("満貫")
      end

      it "数え役満なしルールでは13翻以上でも三倍満止まり" do
        result = described_class.calculate(
          fu: 30, han: 13, is_oya: false, agari_type: :ron,
          rule: Mahjong::Config::RuleConfig.new("kazoe_yakuman" => false)
        )

        expect(result.base_points).to eq(6000)
        expect(result.payments[:ron_pay]).to eq(24000)
        expect(result.level).to eq("三倍満")
      end
    end

    context "本場と供託" do
      it "1本場のロンで +300点" do
        result = described_class.calculate(fu: 30, han: 1, is_oya: false, agari_type: :ron, honba: 1)

        expect(result.payments[:ron_pay]).to eq(1300)
      end

      it "1本場のツモで各 +100点" do
        result = described_class.calculate(fu: 30, han: 5, is_oya: true, agari_type: :tsumo, honba: 1)

        expect(result.payments[:ko_pays]).to eq(4100)
      end

      it "score_changes が供託込みで正しい点数変動を返す" do
        result = described_class.calculate(fu: 30, han: 2, is_oya: false, agari_type: :tsumo, kyoutaku: 1)
        changes = result.score_changes(winner_seat: 1, loser_seat: nil, oya_seat: 0)

        expect(changes[0]).to eq(-1000)
        expect(changes[2]).to eq(-500)
        expect(changes[3]).to eq(-500)
        expect(changes[1]).to eq(3000)
      end

      it "ロンの score_changes を返す" do
        result = described_class.calculate(fu: 40, han: 2, is_oya: true, agari_type: :ron, kyoutaku: 2)
        changes = result.score_changes(winner_seat: 0, loser_seat: 2, oya_seat: 0)

        expect(changes[2]).to eq(-3900)
        expect(changes[0]).to eq(5900)
      end
    end

    context "表示" do
      it "通常手の display を返す" do
        result = described_class.calculate(fu: 30, han: 1, is_oya: false, agari_type: :ron)

        expect(result.display).to eq("30符 1翻 1000点")
      end

      it "満貫の display を返す" do
        result = described_class.calculate(fu: 30, han: 5, is_oya: true, agari_type: :tsumo)

        expect(result.display).to eq("5翻 満貫 4000点オール")
      end
    end
  end
end
