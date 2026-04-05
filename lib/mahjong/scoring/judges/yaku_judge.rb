module Mahjong
  module Scoring
    module Judges
      class YakuJudge
        # 和了時の成立役を全て判定する
        def self.judge(context)
          contexts = contexts_for_judging(context)
          return judge_single(contexts.first) if contexts.one?

          contexts
            .map { |ctx| [judge_single(ctx), ctx] }
            .max_by { |result, ctx| result_sort_key(result, ctx) }
            .first
        end

        def self.judge_single(context)
          yakuman_results = check_yakuman(context)
          unless yakuman_results.empty?
            return ValueObjects::YakuJudgeResult.new(
              yaku: yakuman_results,
              is_yakuman: true,
              total_han: nil
            )
          end

          yaku_results = check_regular_yaku(context)
          dora_results = check_dora(context)

          if yaku_results.empty?
            return ValueObjects::YakuJudgeResult.new(yaku: [], is_yakuman: false, total_han: 0)
          end

          all = yaku_results + dora_results
          total_han = all.sum(&:han)

          ValueObjects::YakuJudgeResult.new(yaku: all, is_yakuman: false, total_han: total_han)
        end

        private

        def self.contexts_for_judging(context)
          return [context] unless context.hand_tiles

          tiles_34 = Tiles::TileSet.to_34(context.hand_tiles)
          forms = Scoring::Judges::AgariJudge.all_forms(tiles_34)
          return [context] if forms.empty?

          forms.map { |form| context.with_agari_form(form) }
        end

        def self.result_sort_key(result, context)
          [
            result.yakuman? ? 1 : 0,
            result.total_han || result.yaku.sum { |entry| entry.han == -1 ? 13 : entry.han },
            estimated_fu(context, result),
            result.yaku.length
          ]
        end

        def self.estimated_fu(context, result)
          return 0 if result.yakuman?
          return 25 if context.agari_form&.chiitoitsu?

          fu = 20

          if context.agari_form&.regular?
            fu += context.all_mentsu.sum(&:fu)

            jantou = context.jantou_tile
            if jantou
              fu += 2 if jantou.sangenpai?
              fu += 2 if context.jikaze_yakuhai?(jantou)
              fu += 2 if context.bakaze_yakuhai?(jantou)
            end

            fu += case context.machi_type
                  when :tanki, :kanchan, :penchan then 2
                  else 0
                  end
          end

          if context.agari_type == :tsumo
            fu += 2 unless result.yaku.any? { |entry| entry.name == "pinfu" }
          elsif context.is_menzen
            fu += 10
          end

          fu
        end

        def self.check_yakuman(context)
          results = []
          YAKUMAN_CHECKERS.each do |checker|
            result = checker.check(context)
            results.concat(Array(result).compact) if result
          end
          results
        end

        def self.check_regular_yaku(context)
          results = []
          REGULAR_CHECKERS.each do |checker|
            result = checker.check(context)
            results.concat(Array(result).compact) if result
          end

          if results.any? { |r| r.name == "ryanpeiko" }
            results.reject! { |r| r.name == "chiitoitsu" }
          end

          results
        end

        def self.check_dora(context)
          results = []
          all_tiles = context.all_tiles

          dora_count = Tiles::Dora.count(all_tiles, context.dora_tiles)
          if dora_count > 0
            results << ValueObjects::YakuEntry.new(name: "dora", han: dora_count, display: "ドラ #{dora_count}")
          end

          if context.is_riichi
            ura_count = Tiles::Dora.uradora_count(all_tiles, context.uradora_tiles)
            if ura_count > 0
              results << ValueObjects::YakuEntry.new(name: "uradora", han: ura_count, display: "裏ドラ #{ura_count}")
            end
          end

          aka_count = Tiles::Dora.aka_count(all_tiles)
          if aka_count > 0
            results << ValueObjects::YakuEntry.new(name: "akadora", han: aka_count, display: "赤ドラ #{aka_count}")
          end

          results
        end

        REGULAR_CHECKERS = [
          Scoring::Yaku::Riichi, Scoring::Yaku::DoubleRiichi, Scoring::Yaku::Ippatsu,
          Scoring::Yaku::MenzenTsumo, Scoring::Yaku::Pinfu, Scoring::Yaku::Iipeiko,
          Scoring::Yaku::Tanyao, Scoring::Yaku::Yakuhai,
          Scoring::Yaku::RinshanKaihou, Scoring::Yaku::Chankan, Scoring::Yaku::Haitei, Scoring::Yaku::Houtei,
          Scoring::Yaku::SanshokuDoujun, Scoring::Yaku::Ikkitsuukan, Scoring::Yaku::Chanta,
          Scoring::Yaku::Chiitoitsu, Scoring::Yaku::Toitoihou, Scoring::Yaku::SanAnkou,
          Scoring::Yaku::SanKantsu, Scoring::Yaku::Honroutou, Scoring::Yaku::Shousangen,
          Scoring::Yaku::SanshokuDoukou,
          Scoring::Yaku::Honitsu, Scoring::Yaku::Junchan, Scoring::Yaku::Ryanpeiko,
          Scoring::Yaku::Chinitsu
        ].freeze

        YAKUMAN_CHECKERS = [
          Scoring::Yaku::Tenhou, Scoring::Yaku::Chiihou,
          Scoring::Yaku::KokushiMusou, Scoring::Yaku::Suuankou,
          Scoring::Yaku::Daisangen, Scoring::Yaku::Shousuushii, Scoring::Yaku::Daisuushii,
          Scoring::Yaku::Tsuuiisou, Scoring::Yaku::Ryuuiisou, Scoring::Yaku::Chinroutou,
          Scoring::Yaku::ChuurenPoutou, Scoring::Yaku::Suukantsu
        ].freeze
      end
    end
  end
end
