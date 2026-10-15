require "json"
require "open3"

# Compares riichi_engine's win evaluation (yaku, han, fu, payments) with the
# Python package `mahjong` (PyPI) on many winning hands: random ones and one or
# more representative hands per yaku. Used by python_mahjong_spec.rb and by
# `ruby spec/compat/run_python_mahjong.rb`. Python is needed only here.
module PythonMahjongCompat
  module_function

  EVAL_SCRIPT = File.expand_path("python_mahjong_eval.py", __dir__)
  ROOT = File.expand_path("../..", __dir__)

  # The riichi_engine rule the cases are evaluated with, and the matching
  # Python options (python_mahjong_eval.py). The Python package gives 4 fu for
  # a pair of the seat wind that is also the round wind; riichi_engine makes it
  # a setting (renpuu_jantou_fu, default 2), set to 4 here. The Python package
  # adds up several yakuman in one hand; riichi_engine does with
  # multiple_yakuman (default false), set here. MULTIPLE_YAKUMAN=0 compares
  # with the default instead (the multiple yakuman then show as rule
  # differences).
  RULE = { "renpuu_jantou_fu" => 4, "multiple_yakuman" => ENV["MULTIPLE_YAKUMAN"] != "0" }.freeze

  KINDS = (%w[m p s].flat_map { |s| (1..9).map { |n| "#{n}#{s}" } } + (1..7).map { |n| "#{n}z" }).freeze
  WINDS = %w[ton nan sha pei].freeze

  def python
    @python ||= [ENV["PYTHON_MAHJONG"], File.join(ROOT, ".venv/bin/python"), "python3"].compact.find do |py|
      next false if py.include?("/") && !File.executable?(py)

      _out, status = Open3.capture2e(py, "-c", "import mahjong")
      status.success?
    rescue Errno::ENOENT
      false
    end
  end

  def python_version
    out, = Open3.capture2(python, "-c", "import importlib.metadata as m; print(m.version('mahjong'))")
    out.strip
  end

  # ---- cases -------------------------------------------------------------

  def base_case(id)
    {
      "id" => id, "concealed" => [], "win" => nil, "melds" => [], "tsumo" => false,
      "riichi" => false, "ippatsu" => false, "double_riichi" => false, "haitei" => false,
      "houtei" => false, "rinshan" => false, "chankan" => false, "tenhou" => false,
      "chiihou" => false, "jikaze" => "nan", "bakaze" => "ton", "dora_hyouji" => [], "uradora_hyouji" => []
    }
  end

  # hand: the concealed tiles (13 for a ron, 14 with the winning tile for a
  # tsumo); melds: "chi:1m2m3m pon:7z7z7z ankan:5p5p5p0p ..."
  def hand_case(id, hand, win:, melds: "", **flags)
    c = base_case(id)
    c["concealed"] = hand.split
    c["win"] = win
    c["melds"] = melds.split.map do |m|
      type, tiles = m.split(":")
      { "type" => type, "tiles" => tiles.scan(/\d[mpsz]/) }
    end
    flags.each { |k, v| c[k.to_s] = v }
    c["dora_hyouji"] = Array(c["dora_hyouji"])
    c["uradora_hyouji"] = Array(c["uradora_hyouji"])
    c
  end

  def representative_cases
    t = ->(*args, **kw) { hand_case(*args, **kw) }
    [
      t.("riichi", "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s", win: "3s", riichi: true),
      t.("ippatsu", "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s", win: "3s", riichi: true, ippatsu: true),
      t.("double_riichi", "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s", win: "3s", riichi: true, double_riichi: true),
      t.("menzen_tsumo", "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s 3s", win: "3s", tsumo: true),
      t.("pinfu_ron", "2m 3m 4m 6m 7m 3p 4p 5p 6s 7s 8s 2p 2p", win: "5m"),
      t.("pinfu_tsumo", "1m 2m 3m 6m 7m 3p 4p 5p 6s 7s 8s 9p 9p 8m", win: "8m", tsumo: true),
      t.("open_pinfu_form", "2m 3m 4m 6m 7m 6s 7s 8s 2p 2p", win: "5m", melds: "chi:3p4p5p"),
      t.("tanyao_open", "2m 3m 4m 6s 7s 8s 2p 2p 5m 5m", win: "5m", melds: "pon:6p6p6p"),
      t.("iipeiko", "2m 2m 3m 3m 4m 4m 6s 7s 8s 9p 9p 1s 2s", win: "3s"),
      t.("haku", "1m 2m 3m 4p 5p 6p 9s 9s 2s 3s", win: "4s", melds: "pon:5z5z5z"),
      t.("hatsu", "1m 2m 3m 4p 5p 6p 9s 9s 2s 3s", win: "4s", melds: "pon:6z6z6z"),
      t.("chun", "1m 2m 3m 4p 5p 6p 9s 9s 2s 3s", win: "4s", melds: "pon:7z7z7z"),
      t.("seat_wind", "1m 2m 3m 4p 5p 6p 9s 9s 2s 3s", win: "4s", melds: "pon:2z2z2z", jikaze: "nan"),
      t.("round_wind", "1m 2m 3m 4p 5p 6p 9s 9s 2s 3s", win: "4s", melds: "pon:1z1z1z", jikaze: "nan"),
      t.("double_wind", "1m 2m 3m 4p 5p 6p 9s 9s 2s 3s", win: "4s", melds: "pon:1z1z1z", jikaze: "ton"),
      t.("double_wind_pair", "1m 2m 3m 4p 5p 6p 7s 8s 2s 3s 4s 1z 1z", win: "9s", jikaze: "ton", riichi: true),
      t.("rinshan", "1m 2m 3m 4p 5p 6p 9s 9s 2s 3s 4s", win: "4s", melds: "ankan:7z7z7z7z", tsumo: true, rinshan: true),
      t.("chankan", "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s", win: "3s", chankan: true, riichi: true),
      t.("haitei", "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 4s 2s", win: "3s", melds: "", tsumo: false, haitei: false, houtei: true),
      t.("haitei_tsumo", "1m 2m 3m 4p 5p 6p 9m 9m 2s 4s 3s", win: "3s", melds: "chi:7s8s9s", tsumo: true, haitei: true),
      t.("sanshoku", "1m 2m 3m 1p 2p 3p 1s 2s 3s 9m 9m 5s 6s", win: "7s"),
      t.("sanshoku_open", "1m 2m 3m 1p 2p 3p 9m 9m 5s 6s", win: "7s", melds: "chi:1s2s3s"),
      t.("ittsu", "1m 2m 3m 4m 5m 6m 7m 8m 9m 9p 9p 5s 6s", win: "7s"),
      t.("ittsu_open", "1m 2m 3m 4m 5m 6m 9p 9p 5s 6s", win: "7s", melds: "chi:7m8m9m"),
      t.("chanta", "1m 2m 3m 7p 8p 9p 1s 2s 3s 1z 1z 9m 9m", win: "9m", jikaze: "nan", bakaze: "nan"),
      t.("chanta_open", "1m 2m 3m 7p 8p 9p 1z 1z 9m 9m", win: "9m", melds: "chi:1s2s3s", jikaze: "nan", bakaze: "nan"),
      t.("junchan", "1m 2m 3m 7p 8p 9p 1s 2s 3s 9s 9s 9m 9m", win: "9m"),
      t.("chiitoitsu", "1m 1m 3p 3p 5s 5s 7m 7m 2z 2z 6p 6p 9s", win: "9s"),
      t.("toitoi", "2m 2m 2m 9p 9p 4s 4s", win: "4s", melds: "pon:6p6p6p pon:8s8s8s"),
      t.("san_ankou", "2m 2m 2m 4p 4p 4p 6s 6s 6s 1m 2m 9p 9p", win: "3m", tsumo: false),
      t.("san_ankou_tsumo", "2m 2m 2m 4p 4p 4p 6s 6s 6s 9p 9p 1m 2m 3m", win: "3m", tsumo: true),
      t.("san_kantsu", "1m 2m 3m 9p 9p", win: "3m", melds: "daiminkan:2s2s2s2s ankan:4p4p4p4p kakan:7z7z7z7z", tsumo: true, rinshan: false),
      t.("honroutou", "1m 1m 1m 9p 9p 1z 1z", win: "1z", melds: "pon:9s9s9s pon:1p1p1p", jikaze: "sha"),
      t.("shousangen", "5z 5z 5z 6z 6z 6z 7z 7z 1m 2m 3m 9p 9p", win: "9p", jikaze: "sha"),
      t.("sanshoku_doukou", "3m 3m 3m 3p 3p 3p 1m 1m 5s 6s", win: "7s", melds: "pon:3s3s3s"),
      t.("honitsu", "1m 2m 3m 4m 5m 6m 9m 9m 2z 2z 7m 8m 3z", win: "9m", tsumo: false, melds: "") .tap { |c| c["concealed"] = %w[1m 2m 3m 4m 5m 6m 9m 9m 2z 2z 2z 7m 8m] },
      t.("honitsu_open", "1m 2m 3m 4m 5m 6m 9m 9m 7m 8m", win: "9m", melds: "pon:2z2z2z", jikaze: "sha"),
      t.("ryanpeiko", "2m 2m 3m 3m 4m 4m 6s 6s 7s 7s 8s 8s 9p", win: "9p"),
      t.("ryanpeiko_same", "6p 7p 8p 6p 7p 8p 6p 7p 8p 6p 7p 8p 2s 2s", win: "7p", tsumo: true),
      t.("iipeiko_triple", "1m 2m 3m 1m 2m 3m 1m 2m 3m 7s 8s 9s 2z", win: "2z", riichi: true),
      t.("shanpon_ron_fu", "5z 5z 5z 2m 2m 6p 7p 8p 3s 4s 5s 9p 9p", win: "2m", jikaze: "sha"),
      t.("tanki_or_ryanmen", "1s 2s 3s 3m 4m 5m 1p 2p 3p 3p 4p 5p 5m 5m", win: "5m", tsumo: true),
      t.("chinitsu", "1m 1m 1m 2m 3m 4m 5m 6m 7m 8m 9m 9m 9m", win: "5m"),
      t.("chinitsu_open", "1m 1m 2m 3m 4m 6m 7m 9m 9m 9m", win: "8m", melds: "chi:4m0m6m"),
      t.("dora_aka", "2m 3m 4m 6m 7m 3p 4p 0p 6s 7s 8s 2p 2p", win: "5m", riichi: true, dora_hyouji: "1m", uradora_hyouji: "1p"),
      t.("kokushi", "1m 9m 1p 9p 1s 9s 1z 2z 3z 4z 5z 6z 7z", win: "1m"),
      t.("suuankou", "2m 2m 2m 4p 4p 4p 6s 6s 6s 8m 8m 8m 9p 9p", win: "9p", tsumo: true),
      t.("daisangen", "5z 5z 5z 6z 6z 6z 7z 7z 1m 2m 3m 9p 9p", win: "7z", jikaze: "sha"),
      t.("shousuushii", "1z 1z 1z 2z 2z 2z 3z 3z 3z 4z 4z 2m 3m", win: "4m"),
      t.("daisuushii", "1z 1z 1z 2z 2z 2z 3z 3z 3z 4z 4z 4z 9m", win: "9m"),
      t.("tsuuiisou", "1z 1z 1z 2z 2z 2z 3z 3z 3z 5z 5z 6z 6z", win: "6z"),
      t.("ryuuiisou", "2s 3s 4s 2s 3s 4s 6s 6s 6s 8s 8s 6z 6z", win: "6z"),
      t.("chinroutou", "1m 1m 1m 9m 9m 9m 1p 1p 1p 9s 9s 1s 1s", win: "1s"),
      t.("chuuren", "1m 1m 1m 2m 3m 4m 5m 6m 7m 8m 9m 9m 9m", win: "2m"),
      t.("suukantsu", "9p", win: "9p", melds: "ankan:1m1m1m1m daiminkan:2s2s2s2s kakan:7z7z7z7z pon:5p5p5p", tsumo: false),
      t.("tenhou", "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s 3s", win: "3s", tsumo: true, tenhou: true, jikaze: "ton"),
      t.("chiihou", "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s 3s", win: "3s", tsumo: true, chiihou: true),
      t.("kanchan_40fu", "1m 2m 3m 4p 5p 6p 7s 8s 9s 9m 9m 2s 4s", win: "3s", riichi: true),
      t.("closed_kan_fu", "2m 3m 4m 6m 7m 3p 4p 5p 2p 2p", win: "8m", melds: "ankan:1z1z1z1z", jikaze: "ton", riichi: true),
      t.("dealer_tsumo", "2m 3m 4m 6m 7m 3p 4p 5p 6s 7s 8s 2p 2p 5m", win: "5m", tsumo: true, riichi: true, jikaze: "ton"),
      t.("kiriage_edge", "1m 1m 1m 3p 4p 5p 6s 7s 8s 2p 2p 3m 4m", win: "5m", riichi: true, dora_hyouji: %w[1p 5s]),
      t.("kazoe", "1m 1m 1m 2m 3m 4m 5m 6m 7m 8m 9m 9m 9m", win: "2m", riichi: true, ippatsu: true, dora_hyouji: %w[8m 9m], uradora_hyouji: %w[8m])
    ].reject { |c| c["id"] == "haitei" }.each { |c| c["id"] = "rep:#{c['id']}" }
  end

  # Random winning hands: four sets and a pair (with calls and kans), seven
  # pairs or the thirteen orphans; random winds, ways of winning and dora.
  def random_cases(count, seed: 1)
    rng = Random.new(seed)
    cases = []
    cases << random_case(rng, "rand:#{cases.size}") until cases.size >= count
    cases
  end

  def new_pool
    KINDS.to_h { |k| [k, k[0] == "5" && k[1] != "z" ? ["0#{k[1]}", k, k, k] : [k] * 4] }
  end

  def take(pool, rng, kind)
    list = pool[kind]
    return nil if list.empty?

    list.delete_at(rng.rand(list.size))
  end

  def random_case(rng, id)
    loop do
      c = try_random_case(rng, id)
      return c if c
    end
  end

  def try_random_case(rng, id)
    pool = new_pool
    c = base_case(id)
    groups = [] # [tiles, concealed?]
    form = rng.rand
    if form < 0.08
      kinds = KINDS.sample(7, random: rng)
      groups = kinds.map { |k| [2.times.map { take(pool, rng, k) }, true] }
    elsif form < 0.10
      yaochu = KINDS.select { |k| k[1] == "z" || %w[1 9].include?(k[0]) }
      tiles = yaochu.map { |k| take(pool, rng, k) } + [take(pool, rng, yaochu.sample(random: rng))]
      groups = [[tiles, true]]
    else
      # one hand in five keeps to one suit (with honors), for the one-suit yaku
      suits = rng.rand < 0.2 ? [%w[m p s].sample(random: rng)] : %w[m p s]
      kinds = KINDS.select { |k| k[1] == "z" || suits.include?(k[1]) }
      4.times do
        if rng.rand < 0.55
          suit = suits.sample(random: rng)
          start = rng.rand(1..7)
          tiles = (start..start + 2).map { |n| take(pool, rng, "#{n}#{suit}") }
          return nil if tiles.include?(nil)

          called = rng.rand < 0.25
          if called
            c["melds"] << { "type" => "chi", "tiles" => tiles }
          else
            groups << [tiles, true]
          end
        else
          kind = rng.rand < 0.35 ? KINDS[27 + rng.rand(7)] : kinds.sample(random: rng)
          kan = rng.rand < 0.12
          tiles = (kan ? 4 : 3).times.map { take(pool, rng, kind) }
          return nil if tiles.include?(nil)

          called = rng.rand < 0.3
          if kan
            type = called ? %w[daiminkan kakan].sample(random: rng) : "ankan"
            c["melds"] << { "type" => type, "tiles" => tiles }
          elsif called
            c["melds"] << { "type" => "pon", "tiles" => tiles }
          else
            groups << [tiles, true]
          end
        end
      end
      kind = kinds.sample(random: rng)
      pair = 2.times.map { take(pool, rng, kind) }
      return nil if pair.include?(nil)

      groups << [pair, true]
    end
    return nil if groups.flat_map(&:first).include?(nil)

    concealed = groups.flat_map(&:first)
    win = concealed.sample(random: rng)
    c["win"] = win
    opened = c["melds"].any? { |m| m["type"] != "ankan" }
    kans = c["melds"].count { |m| m["type"].end_with?("kan") }
    c["tsumo"] = rng.rand < 0.5
    if c["tsumo"]
      c["concealed"] = concealed
    else
      rest = concealed.dup
      rest.delete_at(rest.index(win))
      c["concealed"] = rest
    end
    c["jikaze"] = WINDS.sample(random: rng)
    c["bakaze"] = rng.rand < 0.9 ? %w[ton nan].sample(random: rng) : "sha"
    unless opened
      c["riichi"] = rng.rand < 0.45
      c["double_riichi"] = c["riichi"] && rng.rand < 0.08
      c["ippatsu"] = c["riichi"] && rng.rand < 0.2
    end
    if c["tsumo"]
      c["rinshan"] = kans.positive? && rng.rand < 0.3
      c["haitei"] = !c["rinshan"] && rng.rand < 0.06
      if c["melds"].empty? && !c["riichi"] && rng.rand < 0.03
        c[c["jikaze"] == "ton" ? "tenhou" : "chiihou"] = true
      end
    else
      c["houtei"] = rng.rand < 0.06
      c["chankan"] = !c["houtei"] && rng.rand < 0.03
    end
    c["dora_hyouji"] = (1 + kans).times.map { take(pool, rng, KINDS.sample(random: rng)) }
    c["uradora_hyouji"] = c["riichi"] ? (1 + kans).times.map { take(pool, rng, KINDS.sample(random: rng)) } : []
    return nil if (c["dora_hyouji"] + c["uradora_hyouji"]).include?(nil)

    c
  end

  # ---- riichi_engine -----------------------------------------------------

  def tile(notation)
    Mahjong::Tiles::Tile.new(notation)
  end

  def engine_evaluate(c)
    rule = Mahjong::Config::RuleConfig.new(RULE)
    oya = (0 - WINDS.index(c["jikaze"])) % 4
    state = Mahjong::State::RoundState.new
    state.hands = { 0 => Mahjong::State::Hand.new(c["concealed"].map { tile(_1) }) }
    1.upto(3) { |s| state.hands[s] = Mahjong::State::Hand.new([]) }
    state.fuuros = { 0 => c["melds"].map { |m| fuuro(m) }, 1 => [], 2 => [], 3 => [] }
    state.menzen_flags[0] = c["melds"].all? { |m| m["type"] == "ankan" }
    state.riichi_flags[0] = c["riichi"]
    state.ippatsu_flags[0] = c["ippatsu"]
    state.double_riichi_flags[0] = c["double_riichi"]
    4.times { |s| state.first_turn_flags[s] = false }
    state.first_turn_flags[0] = c["tenhou"] || c["chiihou"]
    state.oya_seat = oya
    state.bakaze = c["bakaze"]
    state.wall = Mahjong::Tiles::Wall.new(c["haitei"] || c["houtei"] ? [] : [tile("1z")])
    state.dora_hyouji = c["dora_hyouji"].map { tile(_1) }
    state.uradora_hyouji = c["uradora_hyouji"].map { tile(_1) }
    state.phase = :round_end
    state.chankan_tile = tile(c["win"]) if c["chankan"]
    snapshot = Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze: c["bakaze"], oya_index: oya, honba: 0, kyoutaku: 0,
                                                             jikaze: c["jikaze"])
    winner, score = RiichiEngine::API.evaluate_win(
      state:, seat: 0, agari_type: c["tsumo"] ? :tsumo : :ron, agari_tile: tile(c["win"]), rule:,
      extra_flags: c["tsumo"] ? { rinshan: c["rinshan"] } : { chankan: c["chankan"] }, snapshot:
    )
    payments = if !c["tsumo"]
                 { "ron" => score.payments[:ron_pay] }
               elsif oya.zero?
                 { "ko" => score.payments[:ko_pays] }
               else
                 { "oya" => score.payments[:oya_pays], "ko" => score.payments[:ko_pays] }
               end
    { "id" => c["id"], "yaku" => winner[:yaku].map { |y| [y[:name], y[:han]] }, "han" => winner[:han],
      "fu" => winner[:fu], "payments" => payments, "yakuman" => score.is_yakuman }
  rescue RiichiEngine::API::EngineError => e
    { "id" => c["id"], "error" => e.message }
  end

  def fuuro(m)
    tiles = m["tiles"].map { tile(_1) }
    type = m["type"].to_sym
    called = type == :ankan ? nil : tiles.first
    Mahjong::State::Fuuro.new(type:, tiles: type == :chi ? tiles.sort : tiles, called_tile: called,
                              from_seat: type == :ankan ? nil : 3)
  end

  # ---- comparison --------------------------------------------------------

  def python_evaluate(cases)
    out, err, status = Open3.capture3(python, EVAL_SCRIPT, stdin_data: JSON.generate(cases))
    raise "python_mahjong_eval.py failed: #{err}" unless status.success?

    JSON.parse(out)
  end

  # Differences between the two answers for one case, as strings.
  def differences(engine, py)
    if engine["error"] || py["error"]
      return [] if engine["error"] && py["error"] == "no_yaku"

      return ["error: engine=#{engine['error'].inspect} python=#{py['error'].inspect}"]
    end

    diffs = []
    ey = yaku_map(engine["yaku"])
    pyy = yaku_map(py["yaku"])
    if engine["yakuman"] || py["yakuman"]
      diffs << "yakuman: engine=#{ey.keys.sort} python=#{pyy.keys.sort}" if ey.keys.sort != pyy.keys.sort
    else
      (ey.keys | pyy.keys).sort.each do |name|
        diffs << "yaku #{name}: engine=#{ey[name].inspect} python=#{pyy[name].inspect}" if ey[name] != pyy[name]
      end
      diffs << "han: engine=#{engine['han']} python=#{py['han']}" if engine["han"] != py["han"]
      diffs << "fu: engine=#{engine['fu']} python=#{py['fu']}" if engine["fu"] != py["fu"] && engine["han"].to_i < 5
    end
    diffs << "payments: engine=#{engine['payments']} python=#{py['payments']}" if engine["payments"] != py["payments"]
    diffs
  end

  def yaku_map(list)
    list.each_with_object(Hash.new(0)) { |(name, han), h| h[name] += han }
  end

  # Differences that come from a rule the two libraries choose differently,
  # not from an error: with multiple_yakuman false riichi_engine scores two or
  # more yakuman in one hand as a single yakuman, the Python package adds them
  # up (as Tenhou does).
  def rule_difference(engine, py)
    return nil unless engine["yakuman"] && py["yakuman"]
    return nil unless engine["yaku"].size > 1 && engine["yaku"].map(&:first).sort == py["yaku"].map(&:first).sort

    "multiple yakuman are not added up"
  end

  # Runs the cases through both and returns
  # [{case, engine, python, diffs, rule}] (rule: a rule_difference, diffs empty).
  def compare(cases)
    py = python_evaluate(cases).to_h { |r| [r["id"], r] }
    cases.map do |c|
      engine = engine_evaluate(c)
      diffs = differences(engine, py[c["id"]])
      rule = diffs.any? ? rule_difference(engine, py[c["id"]]) : nil
      { "case" => c, "engine" => engine, "python" => py[c["id"]], "diffs" => rule ? [] : diffs, "rule" => rule }
    end
  end
end
