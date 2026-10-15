require_relative "../../../spec_helper"

# 包（責任払い）: ルール pao（既定は空 = 0.1.0 と同じく包なし）に挙げた役満で、
# 確定させる鳴きをさせた打牌者が支払いを負う。
RSpec.describe "包（pao）" do
  let(:pao_rule) { Mahjong::Config::RuleConfig.new("pao" => %w[daisangen daisuushii suukantsu]) }
  let(:default_rule) { Mahjong::Config::RuleConfig.new }

  def pon(str, from)
    t = tiles(str)
    Mahjong::State::Fuuro.new(type: :pon, tiles: t, called_tile: t.first, from_seat: from)
  end

  def daiminkan(str, from)
    t = tiles(str)
    Mahjong::State::Fuuro.new(type: :daiminkan, tiles: t, called_tile: t.first, from_seat: from)
  end

  describe "記録（RoundFlow）" do
    let(:snapshot) do
      Mahjong::Snapshots::GameSetupSnapshot.new(
        bakaze: "ton", kyoku: 1, honba: 0, kyoutaku: 0, oya_index: 0,
        scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
      )
    end

    def third_dragon_pon(rule)
      state = RiichiEngine::API.setup_round(game_snapshot: snapshot, rule:, seed: "pao")
      state.fuuros[1] = [pon("5z 5z 5z", 3), pon("6z 6z 6z", 2)]
      state.hands[1] = Mahjong::State::Hand.new(tiles("2m 3m 4m 9p 7z 7z 1s"))
      state.hands[0] = Mahjong::State::Hand.new(tiles("1m 4m 7m 1p 4p 7p 1s 4s 7s 2z 3z 4z 7z"))
      state.hands[2] = Mahjong::State::Hand.new(tiles("2m 5m 8m 2p 5p 8p 2s 5s 8s 1z 3z 6z 4z"))
      state.hands[3] = Mahjong::State::Hand.new(tiles("3m 6m 9m 3p 6p 9p 3s 6s 9s 1z 2z 4z 3z"))
      state.wall = Mahjong::Tiles::Wall.new(tiles("9s") + state.wall.tiles.drop(1))
      RiichiEngine::API.apply_round_action(state:, action: { type: :tsumo }, rule:)
      RiichiEngine::API.apply_round_action(state:, action: { type: :dahai, seat: 0, tile: "7z" }, rule:)
      (state.pending_actions.keys - [1]).each { |seat| RiichiEngine::API.apply_round_action(state:, action: { type: :skip, seat: }, rule:) }
      RiichiEngine::API.apply_round_action(state:, action: { type: :pon, seat: 1 }, rule:)
      state
    end

    it "3 つ目の三元牌をポンさせた席が大三元の包になる" do
      expect(third_dragon_pon(pao_rule).pao_seats[1]).to eq("daisangen" => 0)
    end

    it "既定のルールでは記録しない" do
      expect(third_dragon_pon(default_rule).pao_seats[1]).to eq({})
    end

    it "RoundState の JSON に残り、pao_seats の無い JSON は包なしで読む" do
      state = third_dragon_pon(pao_rule)
      restored = RiichiEngine::API.deserialize_round_state(state.to_json)
      expect(restored.pao_seats[1]).to eq("daisangen" => 0)

      older = JSON.parse(state.to_json).tap { |h| h.delete("pao_seats") }
      expect(RiichiEngine::API.deserialize_round_state(JSON.generate(older)).pao_seats).to eq(0 => {}, 1 => {}, 2 => {}, 3 => {})
    end
  end

  describe "支払い（evaluate_win と ScoreResult#score_changes）" do
    # 席 1（子、親は席 0）が三元牌を 3 つ鳴いた大三元。包は席 0。
    def daisangen_state(pao)
      state = Mahjong::State::RoundState.new
      state.hands = { 0 => Mahjong::State::Hand.new([]), 1 => Mahjong::State::Hand.new(tiles("2m 3m 4m 9p")),
                      2 => Mahjong::State::Hand.new([]), 3 => Mahjong::State::Hand.new([]) }
      state.fuuros = { 0 => [], 1 => [pon("5z 5z 5z", 3), pon("6z 6z 6z", 2), pon("7z 7z 7z", 0)], 2 => [], 3 => [] }
      state.menzen_flags[1] = false
      4.times { |s| state.first_turn_flags[s] = false }
      state.oya_seat = 0
      state.bakaze = "ton"
      state.wall = Mahjong::Tiles::Wall.new(tiles("1z 1z"))
      state.dora_hyouji = []
      state.uradora_hyouji = []
      state.pao_seats[1] = { "daisangen" => 0 } if pao
      state.phase = :round_end
      state
    end

    def changes(state, rule, agari_type, loser: nil, honba: 0)
      tile = Mahjong::Tiles::Tile.new("9p")
      state.hands[1] = state.hands[1].add(tile) if agari_type == :tsumo
      snapshot = Mahjong::Snapshots::WinEvaluationSnapshot.new(bakaze: "ton", oya_index: 0, honba:, kyoutaku: 0, jikaze: "nan")
      winner, score = RiichiEngine::API.evaluate_win(state:, seat: 1, agari_type:, agari_tile: tile, rule:, extra_flags: {}, snapshot:)
      [winner, score.score_changes(winner_seat: 1, loser_seat: loser, oya_seat: 0).to_h.reject { |_s, v| v.zero? }]
    end

    it "ツモは包の席が全額（ロンと同じ 32000、積み棒も）" do
      winner, delta = changes(daisangen_state(true), pao_rule, :tsumo, honba: 1)

      expect(winner[:pao]).to eq([{ seat: 0, yaku: "daisangen" }])
      expect(delta).to eq(0 => -32_300, 1 => 32_300)
    end

    it "ほかの席からのロンは放銃者と包の席が半分ずつ（積み棒は放銃者）" do
      _winner, delta = changes(daisangen_state(true), pao_rule, :ron, loser: 2, honba: 1)

      expect(delta).to eq(0 => -16_000, 2 => -16_300, 1 => 32_300)
    end

    it "pao_honba が liable なら、ほかの席からのロンの積み棒は包の席" do
      rule = Mahjong::Config::RuleConfig.new("pao" => %w[daisangen], "pao_honba" => "liable")
      _winner, delta = changes(daisangen_state(true), rule, :ron, loser: 2, honba: 1)

      expect(delta).to eq(0 => -16_300, 2 => -16_000, 1 => 32_300)
    end

    it "pao_honba が liable でも、包のない和了の積み棒は放銃者" do
      rule = Mahjong::Config::RuleConfig.new("pao" => %w[daisangen], "pao_honba" => "liable")
      _winner, delta = changes(daisangen_state(false), rule, :ron, loser: 2, honba: 1)

      expect(delta).to eq(2 => -32_300, 1 => 32_300)
    end

    it "包の席からのロンは包の席が全額" do
      _winner, delta = changes(daisangen_state(true), pao_rule, :ron, loser: 0)

      expect(delta).to eq(0 => -32_000, 1 => 32_000)
    end

    it "既定のルールではふつうのツモの支払い" do
      winner, delta = changes(daisangen_state(true), default_rule, :tsumo)

      expect(winner).not_to have_key(:pao)
      expect(delta).to eq(0 => -16_000, 2 => -8000, 3 => -8000, 1 => 32_000)
    end

    it "ルールにあっても包の記録が無ければふつうの支払い" do
      _winner, delta = changes(daisangen_state(false), pao_rule, :tsumo)

      expect(delta).to eq(0 => -16_000, 2 => -8000, 3 => -8000, 1 => 32_000)
    end
  end

  describe "大四喜・四槓子の記録" do
    def call_into(state, seat, fuuro, rule)
      state.fuuros[seat] << fuuro
      Mahjong::Flow::Rounds::RoundFlow.send(:record_pao, state, seat, fuuro, rule)
    end

    it "4 つ目の風牌の面子をポンさせた席が大四喜の包" do
      state = Mahjong::State::RoundState.new
      state.fuuros[2] = [pon("1z 1z 1z", 1), pon("2z 2z 2z", 3), pon("3z 3z 3z", 1)]
      call_into(state, 2, pon("4z 4z 4z", 0), pao_rule)

      expect(state.pao_seats[2]).to eq("daisuushii" => 0)
    end

    it "4 つ目の槓を大明槓させた席が四槓子の包" do
      state = Mahjong::State::RoundState.new
      state.fuuros[3] = [daiminkan("1m 1m 1m 1m", 0), Mahjong::State::Fuuro.new(type: :ankan, tiles: tiles("5p 5p 5p 5p")),
                         daiminkan("9s 9s 9s 9s", 1)]
      call_into(state, 3, daiminkan("2z 2z 2z 2z", 2), pao_rule)

      expect(state.pao_seats[3]).to eq("suukantsu" => 2)
    end

    it "3 つ目までの三元牌のポンでは包にならない" do
      state = Mahjong::State::RoundState.new
      state.fuuros[2] = [pon("5z 5z 5z", 1)]
      call_into(state, 2, pon("6z 6z 6z", 0), pao_rule)

      expect(state.pao_seats[2]).to eq({})
    end
  end
end
