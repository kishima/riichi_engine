module Mahjong
  module Flow
    module Rounds
      # 局の進行制御（ステートマシン）。
      class RoundFlow
    # 局を初期化（配牌・ドラ設定）
    # @param game_snapshot [Mahjong::Snapshots::GameSetupSnapshot]
    # @param rule [RuleConfig]
    # @param seed [String, nil]
    # @return [RoundState]
    def self.setup(game_snapshot:, rule:, seed: nil)
      wall = Tiles::Wall.build(aka_config: rule.aka_dora_config, seed: seed)
      wanpai_tiles = Array.new(14) { wall.draw_from_end! }
      wanpai = Tiles::Wanpai.new(wanpai_tiles)

      hands = {}
      4.times do |seat|
        hands[seat] = State::Hand.new(wall.draw_many!(13))
      end

      state = State::RoundState.new
      state.bakaze = game_snapshot.bakaze
      state.kyoku = game_snapshot.kyoku
      state.honba = game_snapshot.honba
      state.kyoutaku = game_snapshot.kyoutaku
      state.oya_seat = game_snapshot.oya_index
      state.hands = hands
      state.fuuros = { 0 => [], 1 => [], 2 => [], 3 => [] }
      state.kawas = { 0 => State::Kawa.new, 1 => State::Kawa.new, 2 => State::Kawa.new, 3 => State::Kawa.new }
      state.scores = game_snapshot.scores.dup
      state.wall = wall
      state.wanpai = wanpai
      state.dora_hyouji = wanpai.dora_hyouji.dup
      state.uradora_hyouji = wanpai.uradora_hyouji.dup
      state.current_seat = game_snapshot.oya_index
      state.junme = 0
      state.phase = :tsumo
      state.last_dahai = nil
      state.last_tsumo = nil

      state.pending_actions = {}
      state
    end

    # アクションを適用
    # @param state [RoundState]
    # @param action [Hash] { type:, seat:, tile:, tiles: }
    # @param rule [RuleConfig]
    # @return [RoundFlowResult]
    def self.apply_action(state:, action:, rule:)
      validation = Validators::ActionValidator.validate(state: state, action: action, rule: rule)
      raise Errors::InvalidActionError, validation.error unless validation.valid?

      events = case action[:type].to_sym
               when :tsumo
                 process_tsumo(state, action, rule)
               when :dahai
                 process_dahai(state, action, rule)
               when :skip
                 process_skip(state, action, rule)
               when :pon
                 process_pon(state, action, rule)
               when :chi
                 process_chi(state, action, rule)
               when :riichi
                 process_riichi(state, action, rule)
               when :ankan
                 process_ankan(state, action, rule)
               when :kakan
                 process_kakan(state, action, rule)
               when :daiminkan
                 process_daiminkan(state, action, rule)
               when :tsumo_agari
                 process_tsumo_agari(state, action, rule)
               when :ron_agari
                 process_ron_agari(state, action, rule)
               when :kyuushu_kyuuhai
                 process_kyuushu_kyuuhai(state, action, rule)
               when :sanchahou
                 process_sanchahou(state, action, rule)
               else
                 raise Errors::InvalidActionError, "unsupported action: #{action[:type]}"
               end

      Results::RoundFlowResult.new(
        state: state,
        events: events,
        round_end: state.phase == :round_end,
        round_end_info: state.instance_variable_get(:@round_end_info)
      )
    end

    # 指定プレイヤーが可能なアクション一覧を取得
    # @param state [RoundState]
    # @param seat [Integer]
    # @param rule [RuleConfig]
    # @return [Array<Hash>]
    def self.available_actions(state:, seat:, rule:)
      case state.phase
      when :tsumo
        []
      when :dahai
        return [] unless state.current_seat == seat

        actions = if state.riichi_flags[seat]
                    state.last_tsumo ? [{ type: :dahai, tile: state.last_tsumo.to_s }] : []
                  else
                    state.hands[seat].tiles.uniq(&:to_s).map { |tile| { type: :dahai, tile: tile.to_s } }
                  end

        if !state.riichi_flags[seat] && can_riichi?(state, seat, rule)
          choices = riichi_dahai_candidates(state, seat)
          actions << { type: :riichi, choices: choices } if choices.any?
        end

        if can_tsumo_agari?(state, seat, rule)
          actions << { type: :tsumo_agari }
        end

        unless state.riichi_flags[seat]
          ankan_candidates(state, seat, rule).each do |tile|
            actions << { type: :ankan, tile: tile }
          end

          kakan_candidates(state, seat).each do |tile|
            actions << { type: :kakan, tile: tile }
          end
        end

        actions << { type: :kyuushu_kyuuhai } if !state.riichi_flags[seat] && can_kyuushu?(state, seat)
        actions
      when :naki_wait
        return [] if state.current_seat == seat
        return [] unless state.pending_actions.key?(seat)

        pending = state.pending_actions[seat]
        return pending.select { |action| action[:type].to_sym == :ron_agari } if state.riichi_flags[seat]

        normalized = []
        chi_actions, other_actions = pending.partition { |action| action[:type].to_sym == :chi }

        normalized.concat(other_actions)
        if chi_actions.any?
          chi_choices = chi_actions.map { |action| Array(action[:tiles]).map(&:to_s) }.uniq
          normalized << if chi_choices.one?
                          { type: :chi, tiles: chi_choices.first }
                        else
                          { type: :chi, choices: chi_choices }
                        end
        end

        normalized + [{ type: :skip }]
      else
        []
      end
    end

    def self.process_tsumo(state, _action, _rule)
      clear_agari_flags(state)

      if state.wall.remaining <= 0
        state.phase = :round_end
        set_round_end_info(state, result_type: :ryuukyoku)
        return [{ type: :ryuukyoku }]
      end

      tile = state.wall.draw!
      seat = state.current_seat

      state.hands[seat] = state.hands[seat].add(tile)
      state.last_tsumo = tile
      state.phase = :dahai
      state.junme += 1 if seat == state.oya_seat

      [{ type: :tsumo, seat: seat, tile: tile.to_s }]
    end

    def self.process_kyuushu_kyuuhai(state, action, _rule)
      state.phase = :round_end
      set_round_end_info(state, result_type: :kyuushu_kyuuhai, seat: action[:seat])

      [{ type: :kyuushu_kyuuhai, seat: action[:seat] }]
    end

    def self.process_dahai(state, action, rule)
      seat = state.current_seat
      tile = hand_tile(state.hands[seat], action[:tile])
      tsumogiri = state.last_tsumo && tile.same_kind?(state.last_tsumo) && state.hands[seat].count_of(tile) <= 1

      state.hands[seat] = state.hands[seat].remove(tile)
      state.kawas[seat].add(tile, tsumogiri: tsumogiri, riichi: action[:riichi] || false)
      state.last_dahai = { seat: seat, tile: tile }
      state.last_tsumo = nil
      state.ippatsu_flags[seat] = false if state.riichi_flags[seat] && !action[:riichi]
      clear_agari_flags(state)
      # 第一打牌が済んだのはこの席だけ（ほかの席の第一巡は、鳴きが入るまで続く）
      state.first_turn_flags[seat] = false

      naki_options = Detectors::NakiDetector.detect(state: state, dahai_seat: seat, dahai_tile: tile, rule: rule)
      if naki_options.any?
        state.phase = :naki_wait
        state.pending_actions = naki_options
      else
        advance_turn(state)
      end

      [{ type: :dahai, seat: seat, tile: tile.to_s, tsumogiri: tsumogiri }]
    end

    def self.process_skip(state, action, rule)
      seat = action[:seat]
      state.pending_actions.delete(seat)
      agari_tile = state.chankan_tile || state.last_dahai&.dig(:tile)

      if agari_tile && can_ron_without_furiten?(state, seat, agari_tile, rule)
        state.dojun_furiten_flags[seat] = true
        state.riichi_furiten_flags[seat] = true if state.riichi_flags[seat]
      end

      if state.pending_actions.empty?
        if state.chankan_tile
          finalize_kakan(state)
        else
          advance_turn(state)
        end
      end
      [{ type: :skip, seat: seat }]
    end

    def self.process_pon(state, action, _rule)
      seat = action[:seat]
      called_tile = state.last_dahai[:tile]
      tiles = hand_tiles(state.hands[seat], action[:tiles] || pon_choices(state, seat, called_tile))

      state.hands[seat] = state.hands[seat].remove_tiles(tiles)
      state.fuuros[seat] << State::Fuuro.new(
        type: :pon,
        tiles: tiles + [called_tile],
        called_tile: called_tile,
        from_seat: state.last_dahai[:seat]
      )
      state.kawas[state.last_dahai[:seat]].mark_last_called!
      state.current_seat = seat
      state.phase = :dahai
      state.pending_actions = {}
      state.menzen_flags[seat] = false
      state.last_tsumo = nil
      clear_ippatsu_flags(state)
      clear_first_turn_flags(state)

      [{ type: :pon, seat: seat, tiles: tiles.map(&:to_s) }]
    end

    def self.process_chi(state, action, _rule)
      seat = action[:seat]
      called_tile = state.last_dahai[:tile]
      tiles = hand_tiles(state.hands[seat], action[:tiles] || action[:choice] || chi_choices(state, seat, called_tile).first)

      state.hands[seat] = state.hands[seat].remove_tiles(tiles)
      state.fuuros[seat] << State::Fuuro.new(
        type: :chi,
        tiles: (tiles + [called_tile]).sort,
        called_tile: called_tile,
        from_seat: state.last_dahai[:seat]
      )
      state.kawas[state.last_dahai[:seat]].mark_last_called!
      state.current_seat = seat
      state.phase = :dahai
      state.pending_actions = {}
      state.menzen_flags[seat] = false
      state.last_tsumo = nil
      clear_ippatsu_flags(state)
      clear_first_turn_flags(state)

      [{ type: :chi, seat: seat, tiles: tiles.map(&:to_s) }]
    end

    def self.process_riichi(state, action, rule)
      seat = action[:seat]
      state.riichi_flags[seat] = true
      state.riichi_junme[seat] = state.junme
      state.ippatsu_flags[seat] = true
      state.double_riichi_flags[seat] = state.first_turn_flags[seat]
      state.scores[seat] -= 1000
      state.kyoutaku += 1

      process_dahai(state, action.merge(riichi: true), rule)
    end

    def self.process_ankan(state, action, _rule)
      seat = action[:seat]
      tile = Tiles::Tile.new(action[:tile])
      removed = state.hands[seat].tiles.select { |t| t.same_kind?(tile) }.first(4)

      state.hands[seat] = state.hands[seat].remove_tiles(removed)
      state.fuuros[seat] << State::Fuuro.new(type: :ankan, tiles: removed)
      apply_kan_transition(state, seat, tile, open_kan: false)

      [{ type: :ankan, seat: seat, tile: tile.to_s }]
    end

    def self.process_kakan(state, action, rule)
      seat = action[:seat]
      tile = hand_tile(state.hands[seat], action[:tile])
      target_fuuro = state.fuuros[seat].find { |fuuro| fuuro.pon? && fuuro.tiles.all? { |t| t.same_kind?(tile) } }
      raise Errors::InvalidActionError, "pon fuuro not found for kakan" unless target_fuuro

      state.hands[seat] = state.hands[seat].remove(tile)
      state.fuuros[seat] = state.fuuros[seat].reject { |fuuro| fuuro.equal?(target_fuuro) }
      state.fuuros[seat] << State::Fuuro.new(type: :kakan, tiles: target_fuuro.tiles + [tile], called_tile: target_fuuro.called_tile, from_seat: target_fuuro.from_seat)
      state.current_seat = seat
      state.chankan_tile = tile
      state.last_dahai = { seat: seat, tile: tile }

      pending_actions = detect_chankan_actions(state, seat, rule)
      if pending_actions.any?
        state.phase = :naki_wait
        state.pending_actions = pending_actions
      else
        finalize_kakan(state)
      end

      [{ type: :kakan, seat: seat, tile: tile.to_s }]
    end

    def self.process_daiminkan(state, action, _rule)
      seat = action[:seat]
      tile = state.last_dahai[:tile]
      removed = state.hands[seat].tiles.select { |t| t.same_kind?(tile) }.first(3)

      state.hands[seat] = state.hands[seat].remove_tiles(removed)
      state.fuuros[seat] << State::Fuuro.new(type: :daiminkan, tiles: removed + [tile], called_tile: tile, from_seat: state.last_dahai[:seat])
      state.kawas[state.last_dahai[:seat]].mark_last_called!
      state.current_seat = seat
      state.menzen_flags[seat] = false
      apply_kan_transition(state, seat, tile, open_kan: true, keep_turn: true)

      [{ type: :daiminkan, seat: seat, tile: tile.to_s }]
    end

    def self.process_tsumo_agari(state, action, _rule)
      seat = action[:seat]
      state.phase = :round_end
      set_round_end_info(state, result_type: :tsumo_agari, winner_seat: seat, rinshan: state.rinshan_flag)

      [{ type: :tsumo_agari, seat: seat }]
    end

    # seats: があれば全員の和了（ダブロン）。winners は放銃者の下家から順に並び、
    # 先頭（頭はねなら和了る席）が winner_seat。
    def self.process_ron_agari(state, action, _rule)
      from = state.last_dahai[:seat]
      seats = Array(action[:seats] || action[:seat]).uniq.sort_by { |seat| (seat - from) % 4 }
      state.phase = :round_end
      set_round_end_info(
        state,
        result_type: :ron_agari,
        winner_seat: seats.first,
        loser_seat: from,
        chankan: !state.chankan_tile.nil?
      )
      info = state.instance_variable_get(:@round_end_info)
      info[:winners] = seats.map { |seat| { seat: seat } }

      seats.map { |seat| { type: :ron_agari, seat: seat, from: from } }
    end

    # 三家和: 3 人がロンを宣言した局は流局（途中流局）。
    def self.process_sanchahou(state, action, _rule)
      state.phase = :round_end
      set_round_end_info(state, result_type: :sanchahou, draw_reason: :sanchahou, ron_seats: Array(action[:seats]).sort)

      [{ type: :sanchahou, seats: Array(action[:seats]).sort }]
    end

    def self.advance_turn(state)
      if state.wall.remaining <= 0
        state.phase = :round_end
        clear_agari_flags(state)
        set_round_end_info(state, result_type: :ryuukyoku)
        return
      end

      state.current_seat = (state.current_seat + 1) % 4
      state.phase = :tsumo
      state.dojun_furiten_flags[state.current_seat] = false
      clear_agari_flags(state)
    end

    def self.can_tsumo_agari?(state, seat, rule)
      agari_tile = state.last_tsumo
      return false unless agari_tile

      can_agari?(state:, seat:, agari_type: :tsumo, agari_tile:, rule:, extra_flags: { rinshan: state.rinshan_flag })
    end

    def self.can_ron_agari?(state, seat, agari_tile, rule)
      can_agari?(state:, seat:, agari_type: :ron, agari_tile:, rule:, extra_flags: { chankan: !state.chankan_tile.nil? })
    end

    def self.can_agari?(state:, seat:, agari_type:, agari_tile:, rule:, extra_flags: {})
      agari_tile = Tiles::Tile.new(agari_tile) unless agari_tile.is_a?(Tiles::Tile)
      full_hand_tiles = agari_type == :tsumo ? state.hands[seat].tiles.dup : state.hands[seat].tiles.dup + [agari_tile]
      tiles_34 = Tiles::TileSet.to_34(full_hand_tiles)
      return false unless Scoring::Judges::AgariJudge.agari?(tiles_34)

      forms = Scoring::Judges::AgariJudge.all_forms(tiles_34)
      return false if forms.empty?

      base_hand_tiles = remove_one_tile(full_hand_tiles, agari_tile)
      machi_results = Scoring::Judges::MachiJudge.find_machi(Tiles::TileSet.to_34(base_hand_tiles))
      oya_seat = state.oya_seat || 0
      jikaze = %w[ton nan sha pei][(seat - oya_seat) % 4]

      candidates = forms.flat_map do |form|
        machi_types = machi_results.select do |result|
          matching_form?(result.agari_form, form) && result.tile_index == Tiles::TileSet.tile_index(agari_tile)
        end.map(&:machi_type).uniq
        (machi_types.empty? ? [:tanki] : machi_types).map { |machi_type| [form, machi_type] }
      end

      candidates.any? do |form, machi_type|
        context = Scoring::ValueObjects::YakuContext.new(
          agari_form: form,
          agari_tile: agari_tile,
          agari_type: agari_type,
          hand_tiles: full_hand_tiles,
          fuuros: state.fuuros[seat],
          is_menzen: state.menzen_flags[seat],
          jikaze: jikaze,
          bakaze: state.bakaze,
          is_riichi: state.riichi_flags[seat],
          is_double_riichi: state.double_riichi_flags[seat],
          is_ippatsu: state.ippatsu_flags[seat],
          is_first_turn: state.first_turn_flags[seat],
          is_haitei: state.is_haitei?,
          is_houtei: houtei?(state, agari_type, extra_flags),
          is_rinshan: extra_flags[:rinshan] == true,
          is_chankan: extra_flags[:chankan] == true,
          dora_tiles: state.wanpai ? state.wanpai.dora_tiles : [],
          uradora_tiles: state.riichi_flags[seat] && state.wanpai ? state.wanpai.uradora_tiles : [],
          machi_type: machi_type,
          rule: rule
        )

        result = Scoring::Judges::YakuJudge.judge_single(context)
        result.yakuman? || result.total_han.to_i.positive?
      end
    end

    # 河底撈魚は最後の打牌へのロン。判定は局の phase ではなく牌山と和了の種類で行う
    # （ロン候補の検出は打牌の処理中、和了の評価は round_end の後に行われるため）。
    def self.houtei?(state, agari_type, extra_flags)
      agari_type == :ron && state.is_haitei? == true && extra_flags[:chankan] != true
    end
    private_class_method :houtei?

    # 手から出す牌。指定と同じ牌（赤五か否かまで）を優先し、無ければ同じ種類の牌。
    def self.hand_tile(hand, notation)
      tile = Tiles::Tile.new(notation)
      hand.tiles.find { |t| t == tile } || hand.tiles.find { |t| t.same_kind?(tile) } || tile
    end
    private_class_method :hand_tile

    def self.hand_tiles(hand, notations)
      notations.each_with_object([]) do |notation, picked|
        rest = picked.reduce(hand) { |h, t| h.remove(t) }
        picked << hand_tile(rest, notation)
      end
    end
    private_class_method :hand_tiles

    def self.remove_one_tile(tiles, agari_tile)
      removed = false
      tiles.each_with_object([]) do |tile, array|
        if !removed && tile.same_kind?(agari_tile)
          removed = true
        else
          array << tile
        end
      end
    end
    private_class_method :remove_one_tile

    def self.matching_form?(left, right)
      return false unless left.type == right.type
      return true unless left.regular?

      left.parsed_hand.jantou_index == right.parsed_hand.jantou_index &&
        left.parsed_hand.mentsu_notations == right.parsed_hand.mentsu_notations
    end
    private_class_method :matching_form?

    def self.can_riichi?(state, seat, _rule)
      return false unless state.menzen_flags[seat]
      return false if state.riichi_flags[seat]
      return false unless state.scores[seat] >= 1000
      return false unless state.wall.remaining >= 4

      riichi_dahai_candidates(state, seat).any?
    end

    def self.riichi_dahai_candidates(state, seat)
      hand = state.hands[seat]
      hand.tiles.uniq(&:to_s).filter_map do |tile|
        next unless Scoring::Judges::MachiJudge.tenpai?(hand.remove(tile).to_34)

        tile.to_s
      rescue Errors::TileNotFoundError
        nil
      end
    end

    def self.can_kyuushu?(state, seat)
      state.first_turn_flags[seat] &&
        state.kawas[seat].count == 0 &&
        Tiles::TileSet.yaochu_kind_count(state.hands[seat].tiles) >= 9
    end

    def self.can_ron_without_furiten?(state, seat, tile, rule)
      can_ron_agari?(state, seat, tile, rule)
    end

    def self.pon_choices(state, seat, tile)
      state.hands[seat].tiles.select { |t| t.same_kind?(tile) }.first(2).map(&:to_s)
    end

    def self.chi_choices(state, seat, tile)
      Detectors::NakiDetector.find_chi_sets(state.hands[seat], tile)
    end

    def self.ankan_candidates(state, seat, _rule)
      return [] unless kan_available?(state)

      state.hands[seat].tiles
        .group_by { |tile| [tile.suit, tile.effective_number] }
        .select { |_key, tiles| tiles.size >= 4 }
        .values
        .map { |tiles| tiles.first.to_s }
    end

    def self.kakan_candidates(state, seat)
      return [] unless kan_available?(state)

      state.fuuros[seat]
        .select(&:pon?)
        .filter_map do |fuuro|
          tile = fuuro.tiles.first
          tile.to_s if state.hands[seat].count_of(tile) >= 1
        end
    end

    def self.clear_ippatsu_flags(state)
      state.ippatsu_flags.keys.each { |seat| state.ippatsu_flags[seat] = false }
    end

    # 鳴き（暗槓を含む）が入ると、まだ打牌していない席の第一巡も終わる
    # （ダブル立直・地和・九種九牌はできなくなる）。
    def self.clear_first_turn_flags(state)
      state.first_turn_flags.keys.each { |seat| state.first_turn_flags[seat] = false }
    end
    private_class_method :clear_first_turn_flags

    def self.kan_available?(state)
      return true unless state.wanpai

      state.wanpai&.rinshan_remaining.to_i.positive? && state.wanpai&.dora_revealable?
    end

    def self.apply_kan_transition(state, seat, tile, open_kan:, keep_turn: false)
      state.current_seat = seat if keep_turn
      state.phase = :dahai
      state.kan_count += 1
      state.kan_by_player[seat] += 1
      state.rinshan_flag = true
      state.chankan_tile = open_kan ? tile : nil
      state.wanpai.reveal_new_dora!
      state.dora_hyouji = state.wanpai.dora_hyouji.dup
      rinshan_tile = state.wanpai.draw_rinshan!
      state.hands[seat] = state.hands[seat].add(rinshan_tile)
      state.last_tsumo = rinshan_tile
      clear_ippatsu_flags(state)
      clear_first_turn_flags(state)
    end
    private_class_method :apply_kan_transition

    def self.finalize_kakan(state)
      tile = state.chankan_tile
      apply_kan_transition(state, state.current_seat, tile, open_kan: true)
      state.chankan_tile = nil
      state.pending_actions = {}
    end
    private_class_method :finalize_kakan

    def self.detect_chankan_actions(state, kakan_seat, rule)
      options = {}

      4.times do |seat|
        next if seat == kakan_seat

        next unless can_ron_agari?(state, seat, state.chankan_tile, rule)

        furiten = Scoring::Judges::FuritenJudge.judge(state: state, seat: seat)
        options[seat] = [{ type: :ron_agari }] unless furiten.furiten?
      end

      options
    end
    private_class_method :detect_chankan_actions

    def self.clear_agari_flags(state)
      state.rinshan_flag = false
      state.chankan_tile = nil
    end
    private_class_method :clear_agari_flags

    def self.set_round_end_info(state, result_type:, winner_seat: nil, loser_seat: nil, **extra)
      winners = winner_seat.nil? ? [] : [{ seat: winner_seat }]
      losers = loser_seat.nil? ? [] : [{ seat: loser_seat }]

      state.instance_variable_set(
        :@round_end_info,
        {
          type: result_type,
          winner_seat: winner_seat,
          loser_seat: loser_seat,
          result_type: result_type,
          winners: winners,
          losers: losers,
          tenpai_seats: extra[:tenpai_seats] || [],
          draw_reason: extra[:draw_reason],
          score_changes: extra[:score_changes] || {}
        }.merge(extra)
      )
    end
    private_class_method :set_round_end_info
      end
    end
  end
end
