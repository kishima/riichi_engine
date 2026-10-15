# API リファレンス

`RiichiEngine::API` は host app や adapter 層から `riichi_engine` を呼ぶための公開入口です。

局進行・和了評価・点数計算はすべてこのモジュールを経由してください。  
内部 namespace（`Mahjong::Flow::*` 等）を host app から直接呼ぶことは避けてください（詳細は [公開 API ポリシー](public_api_policy.md)）。

牌記法や麻雀用語については [概念・用語集](concepts.md) を参照してください。

---

## 共通の型

### RuleConfig

ゲームルールを保持するオブジェクトです。引数なしでデフォルトルールを使えます。

```ruby
rule = Mahjong::Config::RuleConfig.new                  # デフォルト
rule = Mahjong::Config::RuleConfig.new("kuitan" => false)  # 食い断なし
```

#### RuleConfig の設定項目

| キー | 型 | デフォルト | 説明 |
|---|---|---|---|
| `game_type` | String | `"hanchan"` | `"hanchan"`（東南戦）または `"tonpuu"`（東風戦。`"tonpuusen"` も同じ）。それ以外の値は `RuleConfig.new` が `EngineError` |
| `initial_score` | Integer | `25000` | 開始点数 |
| `oka_origin` | Integer | `30000` | オカの基準点 |
| `uma` | Array | `[20000, 10000, -10000, -20000]` | ウマ（1位から順） |
| `aka_dora` | Hash | `{ "m" => 1, "p" => 1, "s" => 1 }` | スートごとの赤ドラ枚数 |
| `kuitan` | Boolean | `true` | 食い断あり |
| `atozuke` | Boolean | `true` | 後付けあり |
| `double_yakuman` | Boolean | `false` | ダブル役満あり（四暗刻単騎・国士無双十三面・純正九蓮宝燈・大四喜を役満 2 つ分で数える。役の `han` は `-2`。`multiple_yakuman` が偽なら、重なった役満のうちいちばん大きいもの 1 つ） |
| `multiple_yakuman` | Boolean | `false` | 複合役満あり（役満が重なれば役満の数だけ倍。偽なら役満 1 つ） |
| `kazoe_yakuman` | Boolean | `true` | 数え役満あり |
| `kiriage_mangan` | Boolean | `false` | 切り上げ満貫あり |
| `triple_ron_draw` | Boolean | `true` | 三家和で流局 |
| `double_ron` | Boolean | `true` | ダブロンあり |
| `tobi` | Boolean | `true` | トビあり（誰かの点数が 0 点未満になったらゲーム終了。ちょうど 0 点は続行） |
| `nishi_iri` | Boolean | `false` | 西入あり |
| `nishi_iri_threshold` | Integer | `30000` | 西入の基準点 |
| `renpuu_jantou_fu` | Integer | `2` | 連風牌を雀頭にしたときの符 |
| `suufon_renda` | Boolean | `false` | 四風連打で途中流局（鳴きの無い第一巡で 4 人が同じ風牌を切った打牌が通ったとき） |
| `suukaikan` | Boolean | `false` | 四槓散了で途中流局（2 人以上で槓が 4 つになった後の打牌が通ったとき。1 人の 4 槓では流局しない） |
| `suucha_riichi` | Boolean | `false` | 四家立直で途中流局（4 人目のリーチの打牌が通ったとき。供託は場に残る） |
| `nagashi_mangan` | Boolean | `false` | 流し満貫あり（荒牌流局の `round_end_info[:nagashi_seats]` に成立した席。支払いは `calculate_nagashi_mangan_payments`） |
| `pao` | Array | `[]` | 包（責任払い）にする役満の名前（`"daisangen"`・`"daisuushii"`・`"suukantsu"`）。空なら包なし |
| `minkan_dora_after_discard` | Boolean | `false` | 明槓（大明槓・加槓）の新ドラを、槓の直後ではなくその後の打牌のとき（ロンの判定の前）にめくる。打牌の前に次の槓をすればそのときにめくり、嶺上開花ではめくらない。暗槓は常に直後 |
| `agari_yame` | Boolean | `true` | アガリ止めあり（オーラスで首位の親が和了ればゲーム終了。理由 `:all_last_oya_agari`） |
| `tenpai_yame` | Boolean | `false` | テンパイ止めあり（オーラスで首位の親がテンパイで流局すればゲーム終了。理由 `:all_last_oya_tenpai`） |

### Snapshots

局の状態を gem へ渡すための値オブジェクトです。ActiveRecord を含まない plain Ruby の構造体です。

```ruby
Mahjong::Snapshots::GameSetupSnapshot      # 局開始情報
Mahjong::Snapshots::GameProgressSnapshot   # 局終了後の進行情報
Mahjong::Snapshots::FinalResultSnapshot    # ゲーム終了時の最終情報
Mahjong::Snapshots::WinEvaluationSnapshot  # 和了評価用の情報
```

各フィールドは [使用例](usage_examples.md) のコードを参照してください。

### RoundState

局の進行状態を保持するオブジェクトです。  
`setup_round` が返し、`apply_round_action` に渡し続けることで局が進行します。  
JSON へのシリアライズ・デシリアライズが可能なので、キャッシュに保存して復元することもできます。

```ruby
Mahjong::State::RoundState
```

---

## メソッド一覧

### `setup_round(game_snapshot:, rule:, seed: nil)`

局の初期状態を構築します。牌山を生成し、配牌を行い、`RoundState` を返します。

**引数：**

| 引数 | 型 | 説明 |
|---|---|---|
| `game_snapshot` | `GameSetupSnapshot` | 局番・点棒・親座席などの初期情報 |
| `rule` | `RuleConfig` | ゲームルール |
| `seed` | `String \| nil` | 牌山の乱数シード。同じ seed で再現可能。省略するとランダム |

**返り値：** `Mahjong::State::RoundState`

---

### `apply_round_action(state:, action:, rule:)`

局中のアクションを `state` に適用し、結果を返します。  
`state` は破壊的に更新されます。

**引数：**

| 引数 | 型 | 説明 |
|---|---|---|
| `state` | `RoundState` | 現在の局状態 |
| `action` | `Hash` | 適用するアクション |
| `rule` | `RuleConfig` | ゲームルール |

**`action` の形式：**

```ruby
{ type: :tsumo }
{ type: :dahai,          seat: 0, tile: "5m" }
{ type: :riichi,         seat: 0, tile: "3z" }
{ type: :pon,            seat: 1, tiles: %w[5m 5m] }
{ type: :chi,            seat: 1, tiles: %w[4m 6m] }
{ type: :ankan,          seat: 0, tile: "5m" }
{ type: :kakan,          seat: 0, tile: "5m" }
{ type: :daiminkan,      seat: 1 }
{ type: :tsumo_agari,    seat: 0 }
{ type: :ron_agari,      seat: 1 }
{ type: :skip,           seat: 2 }
{ type: :kyuushu_kyuuhai, seat: 0 }
```

アクション種別の詳細は [概念・用語集](concepts.md#アクション種別) を参照してください。

**返り値：** `Mahjong::Results::RoundFlowResult`

| フィールド | 説明 |
|---|---|
| `state` | 更新後の `RoundState` |
| `events` | このアクションで発生したイベントの配列 |
| `round_end?` | 局が終了したか否か |
| `round_end_info` | 局終了情報（`RoundEndInfo`）。局中は `nil` |

**例外：**

| 例外 | 発生条件 |
|---|---|
| `RiichiEngine::API::InvalidActionError` | 不正なアクション（存在しない打牌・権利のない鳴きなど） |
| `RiichiEngine::API::EngineError` | エンジン内部エラー |

---

### `available_round_actions(state:, seat:, rule:)`

指定した `seat` が現在選択できるアクションの一覧を返します。  
`apply_round_action` に渡す `action` の候補を取得するために使います。

**返り値：** `Array<Hash>`

各要素は `{ type: :dahai, tile: "5m" }` のような Hash です。

---

### `resolve_pending_action(pending_actions, from_seat: nil, rule: nil)`

複数の seat が同時に鳴き・ロンを宣言した場合（鳴き競合）に、優先順位を解決して1つのアクションを選びます。

**引数：**

| 引数 | 型 | 説明 |
|---|---|---|
| `pending_actions` | `Hash{Integer => Array<Hash>}` | seat番号 → アクション配列 のマップ |
| `from_seat` | `Integer \| nil` | 打牌（加槓）した seat。渡すと同じ優先度どうしはその下家から順に優先する（頭はね）。省略時は seat 番号の若い順 |
| `rule` | `RuleConfig`（任意） | 渡すと、ロンが複数のときに `double_ron`・`triple_ron_draw` に従う |

**返り値：** `Hash | nil`  
競合を解決したアクション。有効なアクションがない場合は `nil`。

`rule` を渡したときのロンが 2 人以上の場合：

| ロンの人数 | ルール | 返すアクション |
|---|---|---|
| 3 人 | `triple_ron_draw` が真 | `{ type: :sanchahou, seats: [...] }`（三家和の流局） |
| 2 人、または 3 人で `triple_ron_draw` が偽 | `double_ron` が真 | `{ type: :ron_agari, seat: 先頭, seats: [...] }`（全員が和了る） |
| 上のどちらでもない | | 1 人のロン（`rule` を渡さないときと同じ） |

`rule` を省略すると今までどおり 1 つのアクションだけを返します。

#### ダブロンの点数

`seats:` のロンでは `round_end_info[:winners]` が放銃者の下家から順に並び、先頭が `winner_seat` です。
点数は和了った席ごとに `evaluate_win` で求めます。積み棒と供託は `winners` の先頭（頭はねなら和了る席）
だけが受け取るので、2 人目以降の `WinEvaluationSnapshot` は `honba: 0, kyoutaku: 0` で作ります。
親が `winners` に入っていれば連荘です（`judge_next_game_round`）。

三家和（`:sanchahou`）は途中流局で、点数の移動はありません。親の連荘で本場が 1 つ増え、供託は次局へ残ります。

---

### `tenpai_seats(state)`

現在の `RoundState` からテンパイしている座席の一覧を返します。  
流局時のノーテン罰符計算の前に使います。

**返り値：** `Array<Integer>`（例: `[0, 2]`）

---

### `calculate_tenpai_payments(tenpai_seats)`

流局時のノーテン罰符の支払い点数を計算します。  
テンパイ者が受け取り、ノーテン者が支払う形で返します。

**引数：**

| 引数 | 型 | 説明 |
|---|---|---|
| `tenpai_seats` | `Array<Integer>` | テンパイしている座席番号の配列 |

**返り値：** `Hash{Integer => Integer}`

```ruby
# 例: seat 0, 2 がテンパイの場合
# => { 0 => 1500, 1 => -1500, 2 => 1500, 3 => -1500 }
```

正の値が受け取り、負の値が支払いです。

---

### `calculate_nagashi_mangan_payments(nagashi_seats, oya_seat:)`

流し満貫（ルール `nagashi_mangan`）の支払いを計算します。荒牌流局の `round_end_info[:nagashi_seats]` が空でなければ、
ノーテン罰符（`calculate_tenpai_payments`）の代わりにこれを使います。

成立した席はそれぞれ満貫のツモ和了と同じ額を受け取ります（親なら 4000 点オール、子なら親から 4000 点・子から 2000 点）。
本場は付かず、供託は次局へ残ります。親の連荘は通常の流局と同じく親のテンパイで決まります（`tenpai_seats` を渡す）。

```ruby
RiichiEngine::API.calculate_nagashi_mangan_payments([2], oya_seat: 0)
# => { 0 => -4000, 1 => -2000, 2 => 8000, 3 => -2000 }
```

---

### `judge_next_game_round(progress_snapshot:, round_end_info:, rule:)`

局終了後に次局へ進むかゲームを終了するかを判定します。  
オーラス・飛び・ゲーム終了条件なども考慮されます。

**引数：**

| 引数 | 型 | 説明 |
|---|---|---|
| `progress_snapshot` | `GameProgressSnapshot` | 局終了後の点棒・場況 |
| `round_end_info` | `RoundEndInfo` | 局終了の詳細情報 |
| `rule` | `RuleConfig` | ゲームルール |

**返り値：** `Mahjong::Results::GameFlowResult`

`GameFlowResult` の主要フィールド：

| フィールド | 説明 |
|---|---|
| `next_round?` | 次局へ進む場合 `true` |
| `game_end?` | ゲームを終了する場合 `true` |
| `next_bakaze` | 次局の場風（進行する場合） |
| `next_kyoku` | 次局の局番号 |
| `next_honba` | 次局の本場数 |

---

### `calculate_ranked_results(scores:, rule:)`

点棒だけからウマ・オカを含む最終順位と持ち点を計算します。  
プレイヤー情報（名前・ID 等）が不要な場合に使います。

**引数：**

| 引数 | 型 | 説明 |
|---|---|---|
| `scores` | `Hash{Integer => Integer}` | seat番号 → 点棒 のマップ |
| `rule` | `RuleConfig` | ゲームルール |

**返り値：** `Array<Mahjong::Results::FinalResult>`

---

### `calculate_final_results(final_result_snapshot:, rule:)`

プレイヤー情報（名前・ID）付きの最終結果を計算します。  
UI 表示用に情報が必要な場合はこちらを使います。

**引数：**

| 引数 | 型 | 説明 |
|---|---|---|
| `final_result_snapshot` | `FinalResultSnapshot` | 点棒とプレイヤー情報を含むスナップショット |
| `rule` | `RuleConfig` | ゲームルール |

**返り値：** `Array<Mahjong::Results::FinalResult>`

---

### `evaluate_win(state:, seat:, agari_type:, agari_tile:, rule:, extra_flags:, snapshot:)`

和了評価を行い、役一覧・翻数・符・点数計算結果を返します。

**引数：**

| 引数 | 型 | 説明 |
|---|---|---|
| `state` | `RoundState` | 現在の局状態 |
| `seat` | `Integer` | 和了者の座席番号 |
| `agari_type` | `:tsumo \| :ron` | ツモ和了かロン和了か |
| `agari_tile` | `Tile \| String` | 和了牌（例: `"5m"`） |
| `rule` | `RuleConfig` | ゲームルール |
| `extra_flags` | `Hash` | 追加フラグ（チャンカン・リンシャンなど。通常は `{}`） |
| `snapshot` | `WinEvaluationSnapshot` | 場風・自風などの情報 |

**返り値：** `[winner_info, score_result]`

| 要素 | 型 | 説明 |
|---|---|---|
| `winner_info` | `Hash` | 役名・翻数・符を含む情報 |
| `score_result` | `Mahjong::Scoring::ValueObjects::ScoreResult` | 点数・各プレイヤーへの支払い情報（`.payments` で取得） |

#### 包（責任払い）

ルール `pao` に挙げた役満は、確定させる鳴きをさせた打牌者が責任を負います。大三元は 3 つ目の三元牌の面子、
大四喜は 4 つ目の風牌の面子をポンか大明槓させた打牌者、四槓子は 4 つ目の槓を大明槓させた打牌者です
（`RoundState#pao_seats` に `{ 和了る席 => { 役満の名前 => 責任を負う席 } }` で残ります）。

その役満で和了ると、`winner_info[:pao]` に `[{ seat:, yaku: }]` が入り、`score_result.score_changes` が包の分を
次のように割り振ります（`payments` は手の値のままです）。

| 和了 | 包の分 | 積み棒 |
|---|---|---|
| ツモ | 責任者がロンと同じ額を全額 | 責任者 |
| 責任者以外からのロン | 放銃者と責任者が半分ずつ | 放銃者 |
| 責任者からのロン | 責任者が全額 | 責任者 |

包でない役満が重なっている分（複合役満）は、ふつうのツモ・ロンと同じに払います。

---

### `agari?(tiles_34)`

牌の配列が和了形かどうかを判定します。  
34形式については [概念・用語集](concepts.md#34形式tiles_34) を参照してください。

**返り値：** `true | false`

---

### `deserialize_round_state(json)`

JSON 文字列から `RoundState` を復元します。  
Redis やメモリキャッシュに保存した state を復元するときに使います。

**引数：**

| 引数 | 型 | 説明 |
|---|---|---|
| `json` | `String` | `RoundState` をシリアライズした JSON 文字列 |

**返り値：** `Mahjong::State::RoundState`

---

## エラー

```ruby
RiichiEngine::API::InvalidActionError  # 不正なアクション
RiichiEngine::API::EngineError         # エンジン内部エラー
```

adapter 層でこれらを rescue してください。内部エラー（`Mahjong::Errors::*`）を直接 rescue する必要はありません。
