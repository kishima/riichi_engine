module Mahjong
  module State
    # 局の全状態を保持する中核オブジェクト。
    # Solid Cache に JSON シリアライズして保存する。
    # 実装詳細は D09: 局進行ステートマシン で行う。
    class RoundState
    VALID_PHASES = %i[tsumo dahai naki_wait round_end].freeze
    VALID_FUURO_TYPES = %i[chi pon daiminkan ankan kakan].freeze
    VALID_PENDING_ACTION_KEYS = %i[type seat tile tiles].freeze
    VALID_PENDING_ACTION_TYPES = %i[pon chi daiminkan ron_agari skip].freeze

    attr_accessor :bakaze, :kyoku, :honba, :kyoutaku, :oya_seat
    attr_accessor :hands, :fuuros, :kawas, :scores
    attr_accessor :wall, :wanpai, :dora_hyouji, :uradora_hyouji
    attr_accessor :current_seat, :junme, :phase, :last_dahai, :last_tsumo
    attr_accessor :state_version
    attr_accessor :riichi_flags, :riichi_junme, :ippatsu_flags
    attr_accessor :double_riichi_flags, :menzen_flags
    attr_accessor :first_turn_flags, :kan_count, :kan_by_player
    attr_accessor :pending_actions, :rinshan_flag, :chankan_tile
    attr_accessor :dojun_furiten_flags, :riichi_furiten_flags

    def initialize
      @hands         = {}
      @fuuros        = { 0 => [], 1 => [], 2 => [], 3 => [] }
      @kawas         = {}
      @scores        = { 0 => 25000, 1 => 25000, 2 => 25000, 3 => 25000 }
      @riichi_flags  = { 0 => false, 1 => false, 2 => false, 3 => false }
      @riichi_junme  = { 0 => nil,   1 => nil,   2 => nil,   3 => nil }
      @ippatsu_flags = { 0 => false, 1 => false, 2 => false, 3 => false }
      @double_riichi_flags = { 0 => false, 1 => false, 2 => false, 3 => false }
      @menzen_flags  = { 0 => true,  1 => true,  2 => true,  3 => true }
      @first_turn_flags = { 0 => true, 1 => true, 2 => true, 3 => true }
      @kan_count     = 0
      @kan_by_player = { 0 => 0, 1 => 0, 2 => 0, 3 => 0 }
      @pending_actions = {}
      @rinshan_flag  = false
      @chankan_tile  = nil
      @dojun_furiten_flags = { 0 => false, 1 => false, 2 => false, 3 => false }
      @riichi_furiten_flags = { 0 => false, 1 => false, 2 => false, 3 => false }
      @junme         = 0
      @phase         = :tsumo
      @state_version = 0
    end

    # --- クエリ ---

    def is_haitei?
      wall&.remaining == 0
    end

    def is_houtei?
      is_haitei? && phase == :naki_wait
    end

    def is_menzen?(seat)
      menzen_flags[seat] == true
    end

    def is_riichi?(seat)
      riichi_flags[seat] == true
    end

    def remaining_tiles
      wall&.remaining || 0
    end

    # --- シリアライズ（D09 で完全実装）---

    def to_json
      JSON.generate(
        {
        bakaze: bakaze, kyoku: kyoku, honba: honba, kyoutaku: kyoutaku, oya_seat: oya_seat,
        hands: hands.transform_keys(&:to_s).transform_values(&:to_a),
        fuuros: fuuros.transform_keys(&:to_s).transform_values { |list|
          list.map do |fuuro|
            { type: fuuro.type, tiles: fuuro.tiles.map(&:to_s), called_tile: fuuro.called_tile&.to_s, from_seat: fuuro.from_seat }
          end
        },
        kawas: kawas.transform_keys(&:to_s).transform_values(&:to_a),
        scores: scores.transform_keys(&:to_s),
        wall: wall&.to_a,
        wanpai: wanpai&.to_h,
        dora_hyouji: dora_hyouji&.map(&:to_s),
        uradora_hyouji: uradora_hyouji&.map(&:to_s),
        state_version: state_version,
        current_seat: current_seat, junme: junme, phase: phase, last_dahai: serialize_last_dahai, last_tsumo: last_tsumo&.to_s,
        riichi_flags: riichi_flags, riichi_junme: riichi_junme, ippatsu_flags: ippatsu_flags,
        double_riichi_flags: double_riichi_flags, menzen_flags: menzen_flags,
        first_turn_flags: first_turn_flags, kan_count: kan_count, kan_by_player: kan_by_player,
        pending_actions: pending_actions, rinshan_flag: rinshan_flag, chankan_tile: chankan_tile&.to_s,
        dojun_furiten_flags: dojun_furiten_flags, riichi_furiten_flags: riichi_furiten_flags
      }
      )
    end

    def self.from_json(json)
      data = JSON.parse(json)
      state = new

      state.bakaze = data["bakaze"]
      state.kyoku = data["kyoku"]
      state.honba = data["honba"]
      state.kyoutaku = data["kyoutaku"]
      state.oya_seat = data["oya_seat"]
      state.hands = (data["hands"] || {}).transform_keys(&:to_i).transform_values { |tiles| State::Hand.from_array(tiles) }
      state.fuuros = (data["fuuros"] || {}).transform_keys(&:to_i).transform_values do |list|
        Array(list).map do |fuuro|
          type_str = fuuro["type"].to_s
          type_sym = VALID_FUURO_TYPES.find { |t| t.to_s == type_str }
          raise Errors::EngineError, "invalid fuuro type: #{type_str.inspect}" unless type_sym

          State::Fuuro.new(
            type: type_sym,
            tiles: Array(fuuro["tiles"]).map { Tiles::Tile.new(_1) },
            called_tile: fuuro["called_tile"] ? Tiles::Tile.new(fuuro["called_tile"]) : nil,
            from_seat: fuuro["from_seat"]
          )
        end
      end
      state.kawas = (data["kawas"] || {}).transform_keys(&:to_i).transform_values { |arr| State::Kawa.from_array(arr) }
      state.scores = (data["scores"] || {}).transform_keys(&:to_i).transform_values(&:to_i)
      state.wall = data["wall"] ? Tiles::Wall.new(Array(data["wall"]).map { Tiles::Tile.new(_1) }) : nil
      state.wanpai = data["wanpai"] ? Tiles::Wanpai.from_hash(data["wanpai"]) : nil
      state.dora_hyouji = Array(data["dora_hyouji"]).map { Tiles::Tile.new(_1) }
      state.uradora_hyouji = Array(data["uradora_hyouji"]).map { Tiles::Tile.new(_1) }
      state.state_version = data["state_version"].to_i
      state.current_seat = data["current_seat"]
      state.junme = data["junme"]

      phase_str = data["phase"].to_s
      phase_sym = VALID_PHASES.find { |p| p.to_s == phase_str }
      raise Errors::EngineError, "invalid phase: #{phase_str.inspect}" unless phase_sym

      state.phase = phase_sym
      state.last_dahai = deserialize_last_dahai(data["last_dahai"])
      state.last_tsumo = data["last_tsumo"] ? Tiles::Tile.new(data["last_tsumo"]) : nil
      state.riichi_flags = symbolize_int_hash(data["riichi_flags"])
      state.riichi_junme = symbolize_int_hash(data["riichi_junme"])
      state.ippatsu_flags = symbolize_int_hash(data["ippatsu_flags"])
      state.double_riichi_flags = symbolize_int_hash(data["double_riichi_flags"])
      state.menzen_flags = symbolize_int_hash(data["menzen_flags"])
      state.first_turn_flags = symbolize_int_hash(data["first_turn_flags"])
      state.kan_count = data["kan_count"]
      state.kan_by_player = symbolize_int_hash(data["kan_by_player"])
      state.pending_actions = deserialize_pending_actions(data["pending_actions"])
      state.rinshan_flag = data["rinshan_flag"]
      state.chankan_tile = data["chankan_tile"] ? Tiles::Tile.new(data["chankan_tile"]) : nil
      state.dojun_furiten_flags = symbolize_int_hash(data["dojun_furiten_flags"])
      state.riichi_furiten_flags = symbolize_int_hash(data["riichi_furiten_flags"])
      state
    rescue JSON::ParserError, ArgumentError, TypeError, KeyError => e
      raise Errors::EngineError, "RoundState の復元に失敗しました: #{e.message}"
    end

    def serialize_last_dahai
      return nil unless last_dahai

      { seat: last_dahai[:seat], tile: last_dahai[:tile]&.to_s }
    end

    def self.deserialize_last_dahai(value)
      return nil unless value

      { seat: value["seat"], tile: value["tile"] ? Tiles::Tile.new(value["tile"]) : nil }
    end

    def self.symbolize_int_hash(hash)
      (hash || {}).transform_keys(&:to_i)
    end

    def self.deserialize_pending_actions(hash)
      (hash || {}).transform_keys(&:to_i).transform_values do |actions|
        Array(actions).filter_map do |action|
          next unless action

          action.to_h.each_with_object({}) do |(k, v), result|
            key = VALID_PENDING_ACTION_KEYS.find { |s| s.to_s == k.to_s }
            next unless key

            result[key] = if key == :type
              VALID_PENDING_ACTION_TYPES.find { |s| s.to_s == v.to_s } ||
                raise(Errors::EngineError, "invalid pending action type: #{v.inspect}")
            else
              v
            end
          end
        end
      end
    end
    end
  end
end
