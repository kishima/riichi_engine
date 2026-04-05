unless defined?(HandFixtures)
module HandFixtures
  HANDS = {
    riichi_tsumo_tanyao_pinfu: {
      hand: "2m 3m 4m 5p 6p 7p 3s 4s 5s 6s 7s 8s 4m",
      jantou: "4m",
      agari_hai: "8s",
      agari_type: :tsumo,
      expected_yaku: %w[riichi menzen_tsumo tanyao pinfu],
      expected_han: 4,
      expected_fu: 20
    },
    menzen_tsumo_only: {
      hand: "1m 2m 3m 9m 9m 9m 1p 2p 3p 5z 5z 5z 3z",
      jantou: "3z",
      agari_hai: "3z",
      agari_type: :tsumo,
      expected_yaku: %w[menzen_tsumo],
      expected_han: 1,
      expected_fu: 30
    },
    chiitoitsu: {
      hand: "1m 1m 3m 3m 5p 5p 7p 7p 9s 9s 1z 1z 3z 3z",
      agari_hai: "3z",
      agari_type: :tsumo,
      expected_yaku: %w[chiitoitsu menzen_tsumo],
      expected_han: 3,
      expected_fu: 25
    },
    kokushi: {
      hand: "1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z 7z",
      agari_hai: "1m",
      agari_type: :tsumo,
      expected_yaku: %w[kokushi_musou],
      is_yakuman: true
    },
    suuankou: {
      hand: "1m 1m 1m 5p 5p 5p 9s 9s 9s 3z 3z 3z 7z 7z",
      agari_hai: "7z",
      agari_type: :tsumo,
      expected_yaku: %w[suuankou],
      is_yakuman: true
    },
    daisangen: {
      hand: "5z 5z 5z 6z 6z 6z 7z 7z 7z 2m 3m 4m 8p 8p",
      agari_hai: "8p",
      agari_type: :ron,
      expected_yaku: %w[daisangen],
      is_yakuman: true
    },
    chinitsu: {
      hand: "1m 1m 2m 3m 4m 5m 6m 7m 8m 9m 9m 3m 4m 5m",
      agari_hai: "1m",
      agari_type: :ron,
      expected_yaku: %w[chinitsu],
      expected_han: 6
    },
    honitsu_yakuhai: {
      hand: "1p 2p 3p 5p 6p 7p 9p 9p 9p 5z 5z 5z 2p 2p",
      agari_hai: "2p",
      agari_type: :ron,
      expected_yaku: %w[honitsu yakuhai_haku],
      expected_han: 4
    },
    toitoi_sanankou: {
      hand: "3m 3m 3m 7p 7p 7p 2s 2s 2s 5z 5z 5z 9m 9m",
      agari_hai: "9m",
      agari_type: :tsumo,
      expected_yaku: %w[toitoihou san_ankou menzen_tsumo],
      expected_han: 5
    },
    sanshoku: {
      hand: "1m 2m 3m 1p 2p 3p 1s 2s 3s 5m 6m 7m 9s 9s",
      agari_hai: "9s",
      agari_type: :ron,
      expected_yaku: %w[sanshoku_doujun],
      expected_han: 2
    },
    ikkitsuukan: {
      hand: "1m 2m 3m 4m 5m 6m 7m 8m 9m 5p 6p 7p 1z 1z",
      agari_hai: "1z",
      agari_type: :ron,
      expected_yaku: %w[ikkitsuukan],
      expected_han: 2
    },
    chanta: {
      hand: "1m 2m 3m 7p 8p 9p 1s 1s 1s 1z 1z 1z 9m 9m",
      agari_hai: "9m",
      agari_type: :ron,
      expected_yaku: %w[chanta],
      expected_han: 2
    },
    pinfu_ron: {
      hand: "2m 3m 4m 5p 6p 7p 3s 4s 5s 6s 7s 8s 2p 2p",
      agari_hai: "8s",
      agari_type: :ron,
      machi_type: :ryanmen,
      expected_yaku: %w[pinfu],
      expected_han: 1,
      expected_fu: 30
    },
    mangan_ko_ron: {
      hand: "2m 3m 4m 5p 6p 7p 3s 4s 5s 6s 7s 8s 4m 4m",
      agari_hai: "8s",
      agari_type: :ron,
      flags: { is_riichi: true, is_ippatsu: true },
      expected_yaku: %w[riichi ippatsu pinfu tanyao],
      expected_han: 5,
      expected_score: 8000
    }
  }.freeze

  def hand_fixture(name)
    HANDS[name] || raise("Unknown hand fixture: #{name}")
  end
end

RSpec.configure do |config|
  config.include HandFixtures
end
end
