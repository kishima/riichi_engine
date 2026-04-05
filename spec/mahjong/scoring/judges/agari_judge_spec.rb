require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Judges::AgariJudge do
  def t34(*notations)
    tiles = notations.map { |n| Mahjong::Tiles::Tile.new(n) }
    Mahjong::Tiles::TileSet.to_34(tiles)
  end

  describe ".agari?" do
    context "通常形" do
      it "4メンツ1雀頭を和了形と判定する" do
        tiles = t34(
          "1m","2m","3m","4m","5m","6m","7m","8m","9m",
          "1p","2p","3p","1z","1z"
        )
        expect(described_class.agari?(tiles)).to be true
      end

      it "ノーテン手牌を和了形と判定しない" do
        tiles = t34(
          "1m","3m","5m","7m","9m","1p","3p","5p","7p","9p","1z","3z","5z","7z"
        )
        expect(described_class.agari?(tiles)).to be false
      end
    end

    context "七対子" do
      it "7種2枚ずつを和了形と判定する" do
        tiles = t34(
          "1m","1m","2p","2p","3s","3s","1z","1z",
          "2z","2z","3z","3z","4z","4z"
        )
        expect(described_class.agari?(tiles)).to be true
      end

      it "同じ牌4枚を2対子として使えない" do
        # 1m が4枚 → 七対子にならない
        tiles = t34(
          "1m","1m","1m","1m","2p","2p","3s","3s",
          "1z","1z","2z","2z","3z","3z"
        )
        # 七対子としては不成立（同じ牌4枚を2対子に使えない）
        expect(described_class.chiitoitsu?(tiles)).to be false
      end
    end

    context "国士無双" do
      it "13種么九牌＋1枚重複を和了形と判定する" do
        tiles = t34(
          "1m","9m","1p","9p","1s","9s",
          "1z","2z","3z","4z","5z","6z","7z",
          "1m"  # 重複
        )
        expect(described_class.agari?(tiles)).to be true
        expect(described_class.kokushi?(tiles)).to be true
      end

      it "12種しかない場合は国士にならない" do
        tiles = t34(
          "1m","9m","1p","9p","1s","9s",
          "1z","2z","3z","4z","5z","6z",
          "1m","1m"
        )
        expect(described_class.kokushi?(tiles)).to be false
      end
    end
  end

  describe ".all_forms" do
    it "通常形の AgariForm を返す" do
      tiles = t34(
        "1m","2m","3m","4m","5m","6m","7m","8m","9m",
        "1p","2p","3p","1z","1z"
      )
      forms = described_class.all_forms(tiles)
      expect(forms).not_to be_empty
      expect(forms.first.regular?).to be true
    end

    it "七対子の AgariForm を返す" do
      tiles = t34(
        "1m","1m","2p","2p","3s","3s","1z","1z",
        "2z","2z","3z","3z","4z","4z"
      )
      forms = described_class.all_forms(tiles)
      ct = forms.find(&:chiitoitsu?)
      expect(ct).not_to be_nil
      expect(ct.pair_indices.size).to eq(7)
    end

    it "国士無双の AgariForm を返す" do
      tiles = t34(
        "1m","9m","1p","9p","1s","9s",
        "1z","2z","3z","4z","5z","6z","7z",
        "1m"
      )
      forms = described_class.all_forms(tiles)
      kk = forms.find(&:kokushi?)
      expect(kk).not_to be_nil
    end
  end
end
