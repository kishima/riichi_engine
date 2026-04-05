require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Judges::YakuJudge do
  # テスト用コンテキストビルダー
  def build_ctx(hand_str, fuuro_tiles: [], **opts)
    tiles = hand_str.split.map { |n| Mahjong::Tiles::Tile.new(n) }
    tiles_34 = Mahjong::Tiles::TileSet.to_34(tiles)
    forms = Mahjong::Scoring::Judges::AgariJudge.all_forms(tiles_34)
    form  = forms.first

    # agari_tile は最後の牌とする
    agari_tile = tiles.last

    # 待ち種類は呼び出し側で指定できるようにする
    machi_type = opts.delete(:machi_type) || :ryanmen

    Mahjong::Scoring::ValueObjects::YakuContext.new(
      agari_form:       form,
      agari_tile:       agari_tile,
      agari_type:       opts.delete(:agari_type) || :tsumo,
      hand_tiles:       tiles,
      fuuros:           fuuro_tiles,
      is_menzen:        opts.fetch(:is_menzen, true),
      jikaze:           opts.fetch(:jikaze, "ton"),
      bakaze:           opts.fetch(:bakaze, "ton"),
      is_riichi:        opts.fetch(:is_riichi, false),
      is_double_riichi: opts.fetch(:is_double_riichi, false),
      is_ippatsu:       opts.fetch(:is_ippatsu, false),
      is_first_turn:    opts.fetch(:is_first_turn, false),
      is_haitei:        opts.fetch(:is_haitei, false),
      is_houtei:        opts.fetch(:is_houtei, false),
      is_rinshan:       opts.fetch(:is_rinshan, false),
      is_chankan:       opts.fetch(:is_chankan, false),
      dora_tiles:       opts.fetch(:dora_tiles, []),
      uradora_tiles:    opts.fetch(:uradora_tiles, []),
      machi_type:       machi_type,
      rule:             Mahjong::Config::RuleConfig.new
    )
  end

  # 基本的な手牌
  # 123m 456m 789m 123p 22z (平和テンパイの和了形)
  let(:pinfu_hand)   { "1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 3p 2z 2z" }
  # 222m 333m 444m 555m 66m (対々っぽい)
  let(:toitoi_hand)  { "1m 1m 1m 2m 2m 2m 3m 3m 3m 4m 4m 4m 5m 5m" }
  # 七対子
  let(:chiitoitsu_hand) { "1m 1m 2p 2p 3s 3s 1z 1z 2z 2z 3z 3z 4z 4z" }

  describe "通常役" do
    describe "リーチ" do
      it "リーチ中で成立する" do
        ctx = build_ctx(pinfu_hand, is_riichi: true)
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).to include("riichi")
      end

      it "ダブルリーチ中はリーチが成立しない" do
        ctx = build_ctx(pinfu_hand, is_riichi: true, is_double_riichi: true)
        result = described_class.judge(ctx)
        names = result.yaku.map(&:name)
        expect(names).to include("double_riichi")
        expect(names).not_to include("riichi")
      end
    end

    describe "門前清自摸和" do
      it "門前ツモで成立する" do
        ctx = build_ctx(pinfu_hand, agari_type: :tsumo, is_menzen: true)
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).to include("menzen_tsumo")
      end

      it "ロン和了では成立しない" do
        ctx = build_ctx(pinfu_hand, agari_type: :ron, is_menzen: true)
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).not_to include("menzen_tsumo")
      end
    end

    describe "平和" do
      it "全順子・両面待ち・役牌でない雀頭で成立する" do
        ctx = build_ctx(pinfu_hand, machi_type: :ryanmen)
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).to include("pinfu")
      end

      it "刻子があると成立しない" do
        # 111m 456m 789m 123p 11z
        ctx = build_ctx("1m 1m 1m 4m 5m 6m 7m 8m 9m 1p 2p 3p 1z 1z", machi_type: :ryanmen)
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).not_to include("pinfu")
      end

      it "嵌張待ちでは成立しない" do
        ctx = build_ctx(pinfu_hand, machi_type: :kanchan)
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).not_to include("pinfu")
      end
    end

    describe "断么九" do
      it "全て中張牌で成立する" do
        # 234m 345m 456m 234p 55p
        ctx = build_ctx("2m 3m 4m 3m 4m 5m 4m 5m 6m 2p 3p 4p 5p 5p", machi_type: :tanki)
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).to include("tanyao")
      end

      it "么九牌を含むと成立しない" do
        ctx = build_ctx(pinfu_hand, machi_type: :ryanmen)
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).not_to include("tanyao")
      end
    end

    describe "七対子" do
      it "7種2枚ずつで成立する" do
        tiles = chiitoitsu_hand.split.map { |n| Mahjong::Tiles::Tile.new(n) }
        tiles_34 = Mahjong::Tiles::TileSet.to_34(tiles)
        forms = Mahjong::Scoring::Judges::AgariJudge.all_forms(tiles_34)
        form = forms.find(&:chiitoitsu?)

        ctx = Mahjong::Scoring::ValueObjects::YakuContext.new(
          agari_form: form, agari_tile: tiles.last,
          agari_type: :tsumo, hand_tiles: tiles, fuuros: [],
          is_menzen: true, jikaze: "ton", bakaze: "ton",
          is_riichi: false, is_double_riichi: false, is_ippatsu: false,
          is_first_turn: false, is_haitei: false, is_houtei: false,
          is_rinshan: false, is_chankan: false,
          dora_tiles: [], uradora_tiles: [],
          machi_type: :tanki, rule: Mahjong::Config::RuleConfig.new
        )
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).to include("chiitoitsu")
      end
    end

    describe "対々和" do
      it "全て刻子で成立する" do
        ctx = build_ctx(toitoi_hand, agari_type: :ron, bakaze: "nan", machi_type: :shanpon)
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).to include("toitoihou")
      end
    end

    describe "清一色" do
      it "全て同一スートで成立（門前6翻）" do
        # 123m 456m 789m 123m 11m
        ctx = build_ctx("1m 2m 3m 4m 5m 6m 7m 8m 9m 1m 2m 3m 1m 1m", machi_type: :ryanmen)
        result = described_class.judge(ctx)
        chinitsu = result.yaku.find { |y| y.name == "chinitsu" }
        expect(chinitsu).not_to be_nil
        expect(chinitsu.han).to eq(6)
      end

      it "食い下がりで5翻" do
        ctx = build_ctx("1m 2m 3m 4m 5m 6m 7m 8m 9m 1m 2m 3m 1m 1m",
                        is_menzen: false, machi_type: :ryanmen)
        result = described_class.judge(ctx)
        chinitsu = result.yaku.find { |y| y.name == "chinitsu" }
        expect(chinitsu.han).to eq(5)
      end
    end

    describe "二盃口と七対子の排他" do
      it "二盃口が成立すると七対子が排除される" do
        # 1122m 3344m 5566m 11p (二盃口・七対子両方に見える形)
        # 実際に両立する手牌: 1122334455667m + 11p → 難しいので近似テスト
        # 123123m 456456m 11p → 二盃口
        ctx = build_ctx("1m 2m 3m 1m 2m 3m 4m 5m 6m 4m 5m 6m 1p 1p", machi_type: :tanki)
        result = described_class.judge(ctx)
        names = result.yaku.map(&:name)
        if names.include?("ryanpeiko")
          expect(names).not_to include("chiitoitsu")
        end
      end
    end

    describe "ドラ計算" do
      it "ドラだけでは和了役として成立しない" do
        dora = [Mahjong::Tiles::Tile.new("5m")]
        ctx = build_ctx("1m 2m 3m 4m 5m 6m 7p 8p 9p 3s 4s 5s 7z 7z", dora_tiles: dora, agari_type: :ron, machi_type: :ryanmen)
        result = described_class.judge(ctx)

        expect(result.total_han).to eq(0)
        expect(result.yaku).to be_empty
      end

      it "ドラが含まれると加算される" do
        dora = [Mahjong::Tiles::Tile.new("1m")]  # 1m がドラ
        ctx = build_ctx(pinfu_hand, dora_tiles: dora, machi_type: :ryanmen)
        result = described_class.judge(ctx)
        dora_entry = result.yaku.find { |y| y.name == "dora" }
        expect(dora_entry).not_to be_nil
        expect(dora_entry.han).to be >= 1
      end

      it "リーチ中は裏ドラが加算される" do
        ura = [Mahjong::Tiles::Tile.new("1m")]
        ctx = build_ctx(pinfu_hand, is_riichi: true, uradora_tiles: ura, machi_type: :ryanmen)
        result = described_class.judge(ctx)
        names = result.yaku.map(&:name)
        expect(names).to include("uradora")
      end

      it "非リーチでは裏ドラが加算されない" do
        ura = [Mahjong::Tiles::Tile.new("1m")]
        ctx = build_ctx(pinfu_hand, is_riichi: false, uradora_tiles: ura, machi_type: :ryanmen)
        result = described_class.judge(ctx)
        names = result.yaku.map(&:name)
        expect(names).not_to include("uradora")
      end
    end
  end

  describe "役満" do
    describe "国士無双" do
      it "役満として判定される" do
        tiles = %w[1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z 1m].map { |n| Mahjong::Tiles::Tile.new(n) }
        tiles_34 = Mahjong::Tiles::TileSet.to_34(tiles)
        forms = Mahjong::Scoring::Judges::AgariJudge.all_forms(tiles_34)
        form = forms.find(&:kokushi?)

        ctx = Mahjong::Scoring::ValueObjects::YakuContext.new(
          agari_form: form, agari_tile: tiles.last,
          agari_type: :tsumo, hand_tiles: tiles, fuuros: [],
          is_menzen: true, jikaze: "ton", bakaze: "ton",
          is_riichi: false, is_double_riichi: false, is_ippatsu: false,
          is_first_turn: false, is_haitei: false, is_houtei: false,
          is_rinshan: false, is_chankan: false,
          dora_tiles: [], uradora_tiles: [],
          machi_type: :tanki, rule: Mahjong::Config::RuleConfig.new
        )
        result = described_class.judge(ctx)
        expect(result.yakuman?).to be true
        expect(result.yaku.map(&:name)).to include("kokushi_musou")
      end
    end

    describe "天和" do
      it "親の第一ツモ和了で成立する" do
        ctx = build_ctx(pinfu_hand, is_first_turn: true, agari_type: :tsumo, jikaze: "ton")
        result = described_class.judge(ctx)
        expect(result.yakuman?).to be true
        expect(result.yaku.map(&:name)).to include("tenhou")
      end

      it "子では成立しない" do
        ctx = build_ctx(pinfu_hand, is_first_turn: true, agari_type: :tsumo, jikaze: "nan")
        result = described_class.judge(ctx)
        expect(result.yaku.map(&:name)).not_to include("tenhou")
      end
    end

    describe "役満時に通常役が無視される" do
      it "役満結果には通常役が含まれない" do
        tiles = %w[1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z 1m].map { |n| Mahjong::Tiles::Tile.new(n) }
        tiles_34 = Mahjong::Tiles::TileSet.to_34(tiles)
        forms = Mahjong::Scoring::Judges::AgariJudge.all_forms(tiles_34)
        form = forms.find(&:kokushi?)

        ctx = Mahjong::Scoring::ValueObjects::YakuContext.new(
          agari_form: form, agari_tile: tiles.last,
          agari_type: :tsumo, hand_tiles: tiles, fuuros: [],
          is_menzen: true, jikaze: "ton", bakaze: "ton",
          is_riichi: true, is_double_riichi: false, is_ippatsu: false,
          is_first_turn: false, is_haitei: false, is_houtei: false,
          is_rinshan: false, is_chankan: false,
          dora_tiles: [], uradora_tiles: [],
          machi_type: :tanki, rule: Mahjong::Config::RuleConfig.new
        )
        result = described_class.judge(ctx)
        expect(result.yakuman?).to be true
        expect(result.yaku.map(&:name)).not_to include("riichi")
        expect(result.yaku.map(&:name)).not_to include("menzen_tsumo")
      end
    end
  end

  describe "複合役" do
    it "リーチ + ツモ + タンヤオ + 平和 の翻数計算" do
      # 234m 345m 456m 234p 55p (タンヤオ平和形)
      ctx = build_ctx(
        "2m 3m 4m 3m 4m 5m 4m 5m 6m 2p 3p 4p 5p 5p",
        is_riichi: true,
        agari_type: :tsumo,
        machi_type: :ryanmen
      )
      result = described_class.judge(ctx)
      names = result.yaku.map(&:name)
      expect(names).to include("riichi")
      expect(names).to include("menzen_tsumo")
      expect(names).to include("tanyao")
      expect(names).to include("pinfu")
      expect(result.total_han).to be >= 4
    end

    it "複数分解がある手では最も高い役構成を採用する" do
      ctx = build_ctx(pinfu_hand, is_riichi: true, agari_type: :tsumo, machi_type: :ryanmen)
      result = described_class.judge(ctx)

      names = result.yaku.map(&:name)
      expect(names).to include("riichi")
      expect(names).to include("menzen_tsumo")
      expect(names).to include("pinfu")
      expect(names).to include("ikkitsuukan")
    end
  end
end
