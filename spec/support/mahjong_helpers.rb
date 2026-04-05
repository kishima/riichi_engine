unless defined?(MahjongHelpers)
module MahjongHelpers
  def tiles(str)
    str.split.map { |s| Mahjong::Tiles::Tile.new(s) }
  end

  def tiles_34(str)
    Mahjong::Tiles::TileSet.to_34(tiles(str))
  end

  def agari_forms(str)
    Mahjong::Scoring::Judges::AgariJudge.all_forms(tiles_34(str))
  end

  def yaku_context_for(str, form: nil, **overrides)
    hand_tiles = tiles(str)
    resolved_form = form || agari_forms(str).first

    defaults = {
      agari_form: resolved_form,
      agari_tile: hand_tiles.last,
      agari_type: :tsumo,
      hand_tiles: hand_tiles,
      fuuros: [],
      is_menzen: true,
      jikaze: "ton",
      bakaze: "ton",
      is_riichi: false,
      is_double_riichi: false,
      is_ippatsu: false,
      is_first_turn: false,
      is_haitei: false,
      is_houtei: false,
      is_rinshan: false,
      is_chankan: false,
      dora_tiles: [],
      uradora_tiles: [],
      machi_type: :ryanmen,
      rule: Mahjong::Config::RuleConfig.new
    }

    Mahjong::Scoring::ValueObjects::YakuContext.new(**defaults.merge(overrides))
  end
end

RSpec.configure do |config|
  config.include MahjongHelpers
end
end
