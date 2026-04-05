require_relative "../../../spec_helper"

RSpec.describe "Mahjong::Yaku flag-based yaku" do
  describe Mahjong::Scoring::Yaku::Riichi do
    it("リーチで成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_riichi: true))&.name).to eq("riichi") }
    it("ダブル立直中は不成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_riichi: true, is_double_riichi: true))).to be_nil }
  end

  describe Mahjong::Scoring::Yaku::DoubleRiichi do
    it("ダブル立直で成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_double_riichi: true))&.han).to eq(2) }
  end

  describe Mahjong::Scoring::Yaku::Ippatsu do
    it("一発フラグで成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_ippatsu: true))&.name).to eq("ippatsu") }
  end

  describe Mahjong::Scoring::Yaku::MenzenTsumo do
    it("門前ツモで成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", agari_type: :tsumo))&.name).to eq("menzen_tsumo") }
    it("ロンでは不成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", agari_type: :ron))).to be_nil }
  end

  describe Mahjong::Scoring::Yaku::RinshanKaihou do
    it("嶺上フラグで成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_rinshan: true))&.name).to eq("rinshan_kaihou") }
  end

  describe Mahjong::Scoring::Yaku::Chankan do
    it("槍槓フラグで成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_chankan: true))&.name).to eq("chankan") }
  end

  describe Mahjong::Scoring::Yaku::Haitei do
    it("海底ツモで成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_haitei: true, agari_type: :tsumo))&.name).to eq("haitei") }
    it("ロンでは不成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_haitei: true, agari_type: :ron))).to be_nil }
  end

  describe Mahjong::Scoring::Yaku::Houtei do
    it("河底ロンで成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_houtei: true, agari_type: :ron))&.name).to eq("houtei") }
    it("ツモでは不成立") { expect(described_class.check(yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z", is_houtei: true, agari_type: :tsumo))).to be_nil }
  end
end
