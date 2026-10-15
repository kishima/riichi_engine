module Mahjong
  module Scoring
    module Evaluators
      class WinEvaluator
        def self.evaluate(state:, seat:, agari_type:, agari_tile:, rule:, extra_flags:, snapshot:)
          full_hand_tiles = winning_hand_tiles(state, seat, agari_type, agari_tile)
          concealed_hand_tiles = remove_agari_tile(full_hand_tiles, agari_tile)
          forms = Scoring::Judges::AgariJudge.all_forms(Tiles::TileSet.to_34(full_hand_tiles))
          machi_results = Scoring::Judges::MachiJudge.find_machi(Tiles::TileSet.to_34(concealed_hand_tiles))

          candidates = forms.flat_map do |form|
            machi_types = machi_results.select do |result|
              matching_form?(result.agari_form, form) && result.tile_index == Tiles::TileSet.tile_index(agari_tile)
            end.map(&:machi_type).uniq
            (machi_types.empty? ? [:tanki] : machi_types).map { |machi_type| [form, machi_type] }
          end

          scored = candidates.filter_map do |form, machi_type|
            context = ValueObjects::YakuContext.new(
              agari_form: form,
              agari_tile: agari_tile,
              agari_type: agari_type,
              hand_tiles: full_hand_tiles,
              fuuros: state.fuuros[seat],
              is_menzen: state.menzen_flags[seat],
              jikaze: snapshot.jikaze,
              bakaze: snapshot.bakaze,
              is_riichi: state.riichi_flags[seat],
              is_double_riichi: state.double_riichi_flags[seat],
              is_ippatsu: state.ippatsu_flags[seat],
              is_first_turn: state.first_turn_flags[seat],
              is_haitei: state.is_haitei?,
              is_houtei: houtei?(state, agari_type, extra_flags),
              is_rinshan: extra_flags[:rinshan] == true,
              is_chankan: extra_flags[:chankan] == true,
              dora_tiles: dora_tiles_for(state.dora_hyouji),
              uradora_tiles: dora_tiles_for(state.uradora_hyouji),
              machi_type: machi_type,
              rule: rule
            )

            yaku_result = Scoring::Judges::YakuJudge.judge_single(context)
            next if !yaku_result.yakuman? && yaku_result.total_han.to_i <= 0

            fu = Scoring::Calculators::FuCalculator.calculate(context)
            score_result = Scoring::Calculators::ScoreCalculator.calculate(
              fu: fu,
              han: yaku_result.yakuman? ? 13 : yaku_result.total_han,
              is_oya: seat == snapshot.oya_index,
              agari_type: agari_type,
              honba: snapshot.honba,
              kyoutaku: snapshot.kyoutaku,
              is_yakuman: yaku_result.yakuman?,
              rule: rule,
              yakuman_count: yakuman_count(yaku_result, rule),
              pao: pao_parts(state, seat, yaku_result, rule)
            )

            [context, yaku_result, fu, score_result]
          end

          best = scored.max_by do |_context, yaku_result, fu, score_result|
            [
              yaku_result.yakuman? ? 1 : 0,
              score_result.total,
              yaku_result.total_han || 13,
              fu
            ]
          end
          raise Errors::EngineError, "No valid winning result found" unless best

          context, yaku_result, fu, score_result = best
          winner_info = {
            yaku: yaku_result.yaku.map { |entry| { name: entry.name, han: entry.han, display: entry.display } },
            han: yaku_result.yakuman? ? 13 : yaku_result.total_han,
            fu: fu,
            hand_tiles: concealed_hand_tiles.sort.map(&:to_s),
            fuuro_tiles: context.fuuros.flat_map { |fuuro| fuuro.tiles.map(&:to_s) },
            agari_hai: agari_tile.to_s
          }
          winner_info[:pao] = score_result.pao.map { |part| part.slice(:seat, :yaku) } if score_result.pao.any?

          [winner_info, score_result]
        end

        # 役満の数（基本点 8000 の何倍か）。役満の項目の han が -1 なら 1 つ、-2（ダブル役満、
        # double_yakuman のときだけ付く）なら 2 つ。複合役満（multiple_yakuman）なら全部を足し、
        # そうでなければいちばん大きいもの 1 つ。
        def self.yakuman_count(yaku_result, rule)
          return 1 unless yaku_result.yakuman?

          units = yaku_result.yaku.map { |entry| [-entry.han.to_i, 1].max }
          return 1 if units.empty?

          rule&.multiple_yakuman? ? units.sum : units.max
        end
        private_class_method :yakuman_count

        # 包の分: ルール pao にある役満で、その席に責任者が記録されているもの
        # （RoundState#pao_seats）。基本点はその役満の分（ダブル役満なら 2 つ分）で、手の基本点を超えない。
        def self.pao_parts(state, seat, yaku_result, rule)
          targets = Array(rule&.pao).map(&:to_s)
          return [] if targets.empty? || !yaku_result.yakuman?

          liable = (state.respond_to?(:pao_seats) && state.pao_seats && state.pao_seats[seat]) || {}
          remaining = 8000 * yakuman_count(yaku_result, rule)
          yaku_result.yaku.filter_map do |entry|
            next unless targets.include?(entry.name) && liable.key?(entry.name) && remaining.positive?

            base = [8000 * [-entry.han.to_i, 1].max, remaining].min
            remaining -= base
            { seat: liable[entry.name], yaku: entry.name, base_points: base }
          end
        end
        private_class_method :pao_parts

        def self.winning_hand_tiles(state, seat, agari_type, agari_tile)
          tiles = state.hands[seat].tiles.dup
          return tiles if agari_type == :tsumo

          tiles + [agari_tile]
        end
        private_class_method :winning_hand_tiles

        def self.dora_tiles_for(hyouji_tiles)
          Array(hyouji_tiles).map { |tile| Tiles::Tile.new(tile.next_tile_notation) }
        end
        private_class_method :dora_tiles_for

        # 河底撈魚は最後の打牌へのロン（評価は round_end の後に呼ばれるので phase は見ない）。
        def self.houtei?(state, agari_type, extra_flags)
          agari_type == :ron && state.is_haitei? == true && extra_flags[:chankan] != true
        end
        private_class_method :houtei?

        def self.remove_agari_tile(full_hand_tiles, agari_tile)
          removed = false
          full_hand_tiles.each_with_object([]) do |tile, array|
            if !removed && tile.same_kind?(agari_tile)
              removed = true
            else
              array << tile
            end
          end
        end
        private_class_method :remove_agari_tile

        def self.matching_form?(left, right)
          return false unless left.type == right.type
          return true unless left.regular?

          left.parsed_hand.jantou_index == right.parsed_hand.jantou_index &&
            left.parsed_hand.mentsu_notations == right.parsed_hand.mentsu_notations
        end
        private_class_method :matching_form?
      end
    end
  end
end
