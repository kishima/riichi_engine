# Pull request の下書き

`fix/*`・`feat/*` のブランチごとに 1 つ。上流へのプルリクエストは日本語で出す（上流の作者が日本語で書くため）。
どの下書きも日本語。

ブランチはどれも `main`（v0.1.0）から作り、それぞれに修正前に落ちて修正後に通る spec を持つ（`test/karaten-tenpai` は今の動きを固定する spec だけ）。表の「土台」に
ほかのブランチを書いたものは、その上に作ってある（先にそちらを入れる）。それ以外は互いに依存せず、どの順でも
出せる。隣り合う行を触るもの（下に書く）は、後に入れる方に小さな rebase が要る。

| ブランチ | 下書き | 土台 | spec |
|---|---|---|---|
| `fix/dora-indicators` | [fix-dora-indicators.md](fix-dora-indicators.md) | | scoring/evaluators/win_evaluator_spec.rb（新規） |
| `fix/houtei` | [fix-houtei.md](fix-houtei.md) | | flow/rounds/round_flow_spec.rb, flow/detectors/naki_detector_spec.rb |
| `fix/riichi-discard` | [fix-riichi-discard.md](fix-riichi-discard.md) | | round_flow_spec.rb, cpu/ai/base_ai_spec.rb |
| `fix/ippatsu` | [fix-ippatsu.md](fix-ippatsu.md) | | round_flow_spec.rb |
| `fix/red-five` | [fix-red-five.md](fix-red-five.md) | | round_flow_spec.rb, state/hand_spec.rb |
| `fix/call-own-options` | [fix-call-own-options.md](fix-call-own-options.md) | | flow/validators/action_validator_spec.rb |
| `fix/ron-turn-order` | [fix-ron-turn-order.md](fix-ron-turn-order.md) | | flow/resolvers/action_resolver_spec.rb, round_flow_spec.rb |
| `fix/wall-seed` | [fix-wall-seed.md](fix-wall-seed.md) | | tiles/wall_spec.rb |
| `fix/cpu-discard-ukeire` | [fix-cpu-discard-ukeire.md](fix-cpu-discard-ukeire.md) | | cpu/selectors/dahai_selector_spec.rb |
| `fix/tonpuu-game-type` | [fix-tonpuu-game-type.md](fix-tonpuu-game-type.md) | | flow/games/game_flow_spec.rb |
| `fix/zeitwerk-eager-load` | [fix-zeitwerk-eager-load.md](fix-zeitwerk-eager-load.md) | | riichi_engine/loader_spec.rb（新規） |
| `fix/tanyao-red-five` | [fix-tanyao-red-five.md](fix-tanyao-red-five.md) | | tiles/tile_spec.rb, scoring/yaku/tanyao_spec.rb |
| `fix/shanpon-ron-fu` | [fix-shanpon-ron-fu.md](fix-shanpon-ron-fu.md) | | scoring/calculators/fu_calculator_spec.rb |
| `fix/machi-interpretation` | [fix-machi-interpretation.md](fix-machi-interpretation.md) | | scoring/judges/machi_judge_spec.rb, win_evaluator_spec.rb（新規） |
| `fix/ryanpeiko-four-sequences` | [fix-ryanpeiko-four-sequences.md](fix-ryanpeiko-four-sequences.md) | | scoring/yaku/pattern_yaku_spec.rb |
| `fix/multiple-ron` | [fix-multiple-ron.md](fix-multiple-ron.md) | | action_resolver_spec.rb, round_flow_spec.rb, flow/games/game_flow_spec.rb |
| `feat/multiple-yakuman` | [feat-multiple-yakuman.md](feat-multiple-yakuman.md) | | scoring/evaluators/multiple_yakuman_spec.rb（新規）, scoring/calculators/score_calculator_spec.rb |
| `fix/shanten-melds` | [fix-shanten-melds.md](fix-shanten-melds.md) | | cpu/analysis/shanten_spec.rb, tile_evaluator_spec.rb, cpu/selectors/dahai_selector_spec.rb, cpu/judges/naki_judge_spec.rb |
| `fix/first-turn-flags` | [fix-first-turn-flags.md](fix-first-turn-flags.md) | | flow/rounds/first_turn_spec.rb（新規） |
| `fix/cpu-riichi` | [fix-cpu-riichi.md](fix-cpu-riichi.md) | | cpu/judges/riichi_judge_spec.rb, cpu/ai/base_ai_spec.rb |
| `fix/kan-live-wall` | [fix-kan-live-wall.md](fix-kan-live-wall.md) | | flow/rounds/kan_wall_spec.rb（新規） |
| `fix/unknown-game-type` | [fix-unknown-game-type.md](fix-unknown-game-type.md) | `fix/tonpuu-game-type` | config/rule_config_spec.rb, game_flow_spec.rb |
| `fix/tobi-doc` | [fix-tobi-doc.md](fix-tobi-doc.md) | | game_flow_spec.rb |
| `feat/abortive-draws` | [feat-abortive-draws.md](feat-abortive-draws.md) | | flow/rounds/abortive_draw_spec.rb（新規） |
| `feat/nagashi-mangan` | [feat-nagashi-mangan.md](feat-nagashi-mangan.md) | | flow/rounds/nagashi_mangan_spec.rb（新規） |
| `feat/pao` | [feat-pao.md](feat-pao.md) | | scoring/evaluators/pao_spec.rb（新規） |
| `feat/kan-dora-after-discard` | [feat-kan-dora-after-discard.md](feat-kan-dora-after-discard.md) | | flow/rounds/kan_dora_spec.rb（新規） |
| `feat/double-yakuman` | [feat-double-yakuman.md](feat-double-yakuman.md) | `feat/multiple-yakuman` | scoring/evaluators/double_yakuman_spec.rb（新規） |
| `feat/agari-yame` | [feat-agari-yame.md](feat-agari-yame.md) | `fix/tonpuu-game-type` | game_flow_spec.rb |
| `fix/kan-uradora` | [fix-kan-uradora.md](fix-kan-uradora.md) | `fix/dora-indicators` | flow/rounds/kan_uradora_spec.rb（新規） |
| `feat/kuikae` | [feat-kuikae.md](feat-kuikae.md) | | flow/rounds/kuikae_spec.rb（新規） |
| `feat/riichi-ankan` | [feat-riichi-ankan.md](feat-riichi-ankan.md) | | flow/rounds/riichi_ankan_spec.rb（新規） |
| `feat/kokushi-ankan-chankan` | [feat-kokushi-ankan-chankan.md](feat-kokushi-ankan-chankan.md) | | flow/rounds/kokushi_ankan_chankan_spec.rb（新規） |
| `feat/pao-honba` | [feat-pao-honba.md](feat-pao-honba.md) | `feat/pao` | scoring/evaluators/pao_spec.rb |
| `feat/tenhou-best-tile` | [feat-tenhou-best-tile.md](feat-tenhou-best-tile.md) | `feat/double-yakuman` | scoring/evaluators/tenhou_best_tile_spec.rb（新規） |
| `feat/sudden-death` | [feat-sudden-death.md](feat-sudden-death.md) | `feat/agari-yame` | game_flow_spec.rb |
| `fix/dojun-furiten-no-yaku` | [fix-dojun-furiten-no-yaku.md](fix-dojun-furiten-no-yaku.md) | | flow/rounds/dojun_furiten_spec.rb（新規） |
| `test/karaten-tenpai` | [test-karaten-tenpai.md](test-karaten-tenpai.md) | | scoring/judges/karaten_spec.rb（新規、spec だけ） |

## 隣り合う変更（先に入った方の後で rebase が要る）

- `fix/dora-indicators`・`fix/houtei`・`fix/machi-interpretation` は、どれも `WinEvaluator.evaluate` の文脈を作る
  ところを触る。最初と最後はどちらも `win_evaluator_spec.rb` を足す。
- `fix/houtei` と `fix/red-five` は `round_flow.rb` の同じ場所に private の補助メソッドを足す。
- `fix/call-own-options` と `fix/ron-turn-order` は `ActionValidator.highest_priority_action?` の同じ 2 行を触る。
- `fix/ron-turn-order` と `fix/multiple-ron` は、どちらも `ActionResolver.resolve` と `resolve_pending_action` に
  キーワードを足す。両方入れると `from_seat:, rule:` の両方を受け、ロンの席は打牌者から順に並べる。
- `RuleConfig::DEFAULTS` の末尾と `api_reference.md` の RuleConfig の表の末尾には、`feat/*` の各ブランチがキーを足す
  （`feat/abortive-draws`・`feat/nagashi-mangan`・`feat/pao`・`feat/kan-dora-after-discard`・`feat/agari-yame`）。
  後に入れる方は前の行の末尾にカンマを足すだけ。`feat/kuikae`・`feat/riichi-ankan`・`feat/kokushi-ankan-chankan`・
  `feat/pao-honba`・`feat/tenhou-best-tile`・`feat/sudden-death` も同じ（`feat/pao-honba` は `"pao" => []` の次の行）。
- `fix/kan-uradora` は槓で新ドラをめくる行（`apply_kan_transition`）を触る。`feat/kan-dora-after-discard` が入ると、
  その行は `reveal_kan_dora` に移る（槓裏の 1 行もそこへ）。
- `feat/kuikae`・`fix/shanten-melds`・`fix/cpu-riichi` は `BaseAi#think_dahai` の最後の行と `DahaiSelector.select` の
  引数を触る。両方入れると `select(..., seat:, allowed:)`。`feat/kuikae` と `fix/riichi-discard` は
  `ActionValidator` の打牌の検査に 1 行ずつ足す。
- `feat/kokushi-ankan-chankan` は `process_ankan`・`finalize_kakan` を触る。`fix/red-five`（暗槓の牌の取り方）・
  `feat/kan-dora-after-discard`（`rule:` を渡す）と隣り合う。
- `feat/riichi-ankan` は `available_actions` の暗槓の候補を出すところを触る（`fix/riichi-discard` の近く）。
- `feat/sudden-death` は `GameFlow.should_end_game?` を触る（`fix/unknown-game-type` の `else` と隣り合う）。
- `fix/dojun-furiten-no-yaku` は `process_dahai` の鳴きの検出の直後に 1 行と、`process_skip` の後に private の補助メソッドを足す
  （`feat/abortive-draws` の途中流局の判定の直前）。
- `RoundState` の属性・`to_json`・`from_json` の末尾には `feat/pao`（`pao_seats`）と `feat/kan-dora-after-discard`
  （`pending_kan_dora`）が足す。
- `round_flow.rb` の `process_dahai`・`process_skip`・`advance_turn` の前後は、`fix/first-turn-flags`・
  `feat/abortive-draws`・`feat/nagashi-mangan`・`feat/pao`・`feat/kan-dora-after-discard` が触る。
  `apply_kan_transition` は `fix/first-turn-flags`・`fix/kan-live-wall`・`feat/kan-dora-after-discard` が触る。
- `GameFlow` の途中流局の並び（`renchan?`・`calc_next_honba`）は `fix/multiple-ron`（`:sanchahou`）と
  `feat/abortive-draws`（`ABORTIVE_DRAWS` にまとめる）が触る。両方入れると `ABORTIVE_DRAWS` に `:sanchahou` を入れる。
- `ScoreCalculator.calculate` と `WinEvaluator` には `feat/multiple-yakuman`（`yakuman_count:`）と `feat/pao`（`pao:`）が
  キーワードを足す。両方入れると、包の分の上限は `yakuman_count` で求めた手の基本点になる。
- `fix/shanten-melds`・`fix/cpu-riichi`・`fix/cpu-discard-ukeire`・`fix/riichi-discard` は `base_ai.rb`・
  `dahai_selector.rb` の近い行を触る。

## ルールの選び方（決まりが分かれるものは、既定値を 0.1.0 の動きにした）

- 河底撈魚は最後の自摸の後の打牌へのロン。最後の牌での槍槓は槍槓。
- 一発は本人の次の打牌まで。鳴き（暗槓を含む）で消える。
- 第一巡（ダブル立直・地和・九種九牌）は自分の最初の打牌まで。誰かの鳴き（暗槓を含む）で全員の第一巡が終わる。
- `rule:` なしの `resolve_pending_action` はロンを頭はねで 1 人に（打牌者の下家から順）。`rule:` を渡すと
  `double_ron`・`triple_ron_draw` が効く（既定はダブロンあり・3 人は流局）。積み棒と供託は打牌者から見て最初の和了者に。
- 役満の重なりは既定で 1 つ（`multiple_yakuman` で足す）。ダブル役満は既定でなし（`double_yakuman`）。
- 槓のたびに牌山が 1 枚短くなる。海底牌では槓できない。
- トビは 0 点未満で終了、ちょうど 0 点は続行。
- 途中流局（四風連打・四槓散了・四家立直）・流し満貫・包・明槓の新ドラを打牌の後にめくること・テンパイ止めは、
  どれも既定で無効。アガリ止めは既定で有効（0.1.0 の動き）。
- 喰い替え（`kuikae`）は既定であり。禁止にすると現物と筋の両方を禁じる。
- リーチ後の暗槓（`riichi_ankan`）・国士無双の暗槓の搶槓（`kokushi_ankan_chankan`）・天和の和了牌の選び直し
  （`tenhou_best_tile`）・東風戦の南入（`nan_iri`）・サドンデス（`sudden_death`）は既定でなし。包のロンの積み棒は既定で
  放銃者（`pao_honba`）。
- 延長戦（`nishi_iri`・`nan_iri`）のあるルールでは、アガリ止め・テンパイ止めに基準点が要る（`feat/sudden-death`）。
- 同巡内フリテンは待ちで決める。役が無くてロンの候補が出ない待ちの牌の見逃しも同巡内フリテン（`fix/dojun-furiten-no-yaku`）。
- 形式聴牌は手の内に 4 枚ある牌の単騎だけを除く。ポンした牌の 4 枚目の単騎は聴牌（`test/karaten-tenpai`）。

gemspec はすでに `spec.license = "MIT"` を持つ（公開された 0.1.0 も同じ）ので変えるものは無い。

## まだ扱っていないもの（見つけたが後回し）

- リーチの宣言牌がロンされたとき、リーチ棒を戻す（リーチ不成立）扱いが無い（`process_riichi` が宣言の時点で 1000 点を払う）。
- normal・hard の CPU は役の有無を見ずに鳴く（向聴が下がれば鳴く）ので、役の無い鳴き手で和了れない局がある。
- easy の CPU は、向聴数を保つ打牌のうち么九牌を先に、受け入れの少ない方を切る。合法で向聴は落とさないので、
  弱くしてある作りとしてそのままにした。
