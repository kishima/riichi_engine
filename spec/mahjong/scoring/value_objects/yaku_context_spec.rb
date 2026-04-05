require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::ValueObjects::YakuContext do
  describe "#all_tiles / #all_mentsu / #with_agari_form" do
    it "副露込みの全牌と全メンツを返す" do
      fuuro = Mahjong::State::Fuuro.new(type: :pon, tiles: tiles("7z 7z 7z"))
      ctx = yaku_context_for("1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z",
                             agari_type: :ron, fuuros: [fuuro])

      expect(ctx.all_tiles.size).to eq(17)
      expect(ctx.all_mentsu.count).to eq(5)
      expect(ctx.jantou_tile.to_s).to eq("2z")
    end

    it "分解だけ差し替えた新しいコンテキストを作る" do
      forms = agari_forms("1m 1m 1m 2m 2m 2m 3m 3m 3m 4m 4m 4m 5m 5m")
      base = yaku_context_for("1m 1m 1m 2m 2m 2m 3m 3m 3m 4m 4m 4m 5m 5m", form: forms.first)
      replaced = base.with_agari_form(forms.last)

      expect(replaced).not_to equal(base)
      expect(replaced.agari_form).to eq(forms.last)
      expect(replaced.hand_tiles).to eq(base.hand_tiles)
    end
  end
end
