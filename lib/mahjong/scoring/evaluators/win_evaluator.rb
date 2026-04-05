module Mahjong
  module Scoring
    module Evaluators
      class WinEvaluator
        def self.evaluate(state:, seat:, agari_type:, agari_tile:, rule:, extra_flags:, snapshot:)
          full_hand_tiles = winning_hand_tiles(state, seat, agari_type, agari_tile)
          concealed_hand_tiles = remove_agari_tile(full_hand_tiles, agari_tile)
          forms = Scoring::Judges::AgariJudge.all_forms(Tiles::TileSet.to_34(full_hand_tiles))
          machi_results = Scoring::Judges::MachiJudge.find_machi(Tiles::TileSet.to_34(concealed_hand_tiles))

          scored = forms.filter_map do |form|
            machi_type = machi_results.find do |result|
              matching_form?(result.agari_form, form) && result.tile_index == Tiles::TileSet.tile_index(agari_tile)
            end&.machi_type

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
              is_houtei: state.is_houtei?,
              is_rinshan: extra_flags[:rinshan] == true,
              is_chankan: extra_flags[:chankan] == true,
              dora_tiles: state.dora_hyouji,
              uradora_tiles: state.uradora_hyouji,
              machi_type: machi_type || :tanki,
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
              rule: rule
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

          [winner_info, score_result]
        end

        def self.winning_hand_tiles(state, seat, agari_type, agari_tile)
          tiles = state.hands[seat].tiles.dup
          return tiles if agari_type == :tsumo

          tiles + [agari_tile]
        end
        private_class_method :winning_hand_tiles

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
