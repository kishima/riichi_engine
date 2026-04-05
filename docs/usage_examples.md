# 使用例

局開始から終了・次局判定・最終結果計算までの典型的な流れをコード例で示します。

牌記法や用語については [概念・用語集](concepts.md) を参照してください。  
各メソッドの詳細仕様は [API リファレンス](api_reference.md) を参照してください。

---

## 典型的な局の流れ

```
setup_round
  → apply_round_action(:tsumo)
  → available_round_actions / apply_round_action(:dahai)
  → ... (ターンを繰り返す)
  → round_end? == true
  → judge_next_game_round
  → (次局 or ゲーム終了)
```

---

## 1. 局を開始する

まず `RuleConfig` を作り、局の初期状態を `GameSetupSnapshot` に詰めて `setup_round` を呼びます。  
`seed` を指定すると同じ牌山を再現できます（テストや観戦機能に便利です）。

```ruby
rule = Mahjong::Config::RuleConfig.new

snapshot = Mahjong::Snapshots::GameSetupSnapshot.new(
  bakaze:    "ton",  # 東場
  kyoku:     1,      # 東1局
  honba:     0,
  kyoutaku:  0,
  oya_index: 0,      # seat 0 が親
  scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
)

state = RiichiEngine::API.setup_round(
  game_snapshot: snapshot,
  rule:          rule,
  seed:          "round-001"
)
```

---

## 2. 自摸して打牌する

`:tsumo` アクションで手番プレイヤーが牌を引き、`:dahai` で打牌します。  
`available_round_actions` で選択可能なアクションを取得してから打牌するのが基本パターンです。

```ruby
# 自摸
RiichiEngine::API.apply_round_action(
  state:  state,
  action: { type: :tsumo },
  rule:   rule
)

# 現在の手番プレイヤーが選べるアクションを取得
actions = RiichiEngine::API.available_round_actions(
  state: state,
  seat:  state.current_seat,
  rule:  rule
)

# 打牌アクションを選んで適用
dahai = actions.find { |a| a[:type] == :dahai }

result = RiichiEngine::API.apply_round_action(
  state:  state,
  action: { type: :dahai, seat: state.current_seat, tile: dahai[:tile] },
  rule:   rule
)
```

`result` は `Mahjong::Results::RoundFlowResult` で、以下のフィールドを持ちます。

| フィールド | 説明 |
|---|---|
| `result.events` | このアクションで発生したイベントの配列 |
| `result.round_end?` | 局が終了したか否か |
| `result.round_end_info` | 局終了情報（局中は `nil`） |

打牌後に他の座席が鳴き・ロンを宣言できる場合、`state.pending_actions` にその情報が入ります。

---

## 3. 鳴き競合を解決する

複数の座席が同時に鳴き・ロンを宣言した場合（例：複数人がロンを宣言、またはロンとポンが競合）、  
`resolve_pending_action` で優先アクションを決定してから適用します。

```ruby
resolved = RiichiEngine::API.resolve_pending_action(state.pending_actions)

if resolved
  RiichiEngine::API.apply_round_action(
    state:  state,
    action: resolved,
    rule:   rule
  )
end
```

`resolved` が `nil` の場合、有効な鳴きがなかった（全員スキップ）ことを意味します。

---

## 4. 流局時のテンパイ料を計算する

`round_end?` が `true` かつ流局だった場合、テンパイ座席を調べてノーテン罰符を計算します。

```ruby
tenpai = RiichiEngine::API.tenpai_seats(state)
# => [0, 2]  # seat 0, 2 がテンパイ

payments = RiichiEngine::API.calculate_tenpai_payments(tenpai)
# => { 0 => 1500, 1 => -1500, 2 => 1500, 3 => -1500 }
# 正が受け取り、負が支払い
```

---

## 5. 和了評価をする

ロンや自摸で局が終了した場合、`evaluate_win` で役・翻・符・点数を取得します。  
`WinEvaluationSnapshot` に場風・自風などの情報を詰めて渡します。

```ruby
win_snapshot = Mahjong::Snapshots::WinEvaluationSnapshot.new(
  bakaze:    state.bakaze,
  oya_index: state.oya_seat,
  honba:     state.honba,
  kyoutaku:  state.kyoutaku,
  jikaze:    "ton"  # 和了者の自風
)

winner_info, score_result = RiichiEngine::API.evaluate_win(
  state:       state,
  seat:        0,
  agari_type:  :tsumo,          # :tsumo or :ron
  agari_tile:  state.last_tsumo,
  rule:        rule,
  extra_flags: {},
  snapshot:    win_snapshot
)
```

`winner_info` には役名・翻数・符などが含まれます。  
`score_result.payments` で各プレイヤーへの支払い点数（正: 受け取り、負: 支払い）を取得できます。

---

## 6. 局終了後に次局を判定する

`judge_next_game_round` で次局へ進むかゲームを終了するかを判定します。  
本場の加算・オーラス条件・飛び判定も自動的に処理されます。

```ruby
progress_snapshot = Mahjong::Snapshots::GameProgressSnapshot.new(
  bakaze:    "ton",
  kyoku:     1,
  honba:     0,
  kyoutaku:  0,
  oya_index: 0,
  scores: { 0 => 24_000, 1 => 26_000, 2 => 25_000, 3 => 25_000 }
)

round_end_info = Mahjong::Results::RoundEndInfo.new(
  result_type:   :ron,
  winners:       [{ seat: 1 }],
  losers:        [{ seat: 0 }],
  tenpai_seats:  [],
  draw_reason:   nil,
  score_changes: {}
)

flow_result = RiichiEngine::API.judge_next_game_round(
  progress_snapshot: progress_snapshot,
  round_end_info:    round_end_info,
  rule:              rule
)

# flow_result.next_round? => true なら次局へ
# flow_result.game_end?   => true ならゲーム終了
```

---

## 7. 最終結果・順位を計算する

### プレイヤー情報が不要な場合

点棒から直接順位・ウマ・オカを計算します。

```ruby
ranked = RiichiEngine::API.calculate_ranked_results(
  scores: { 0 => 35_000, 1 => 28_000, 2 => 22_000, 3 => 15_000 },
  rule:   rule
)
```

### プレイヤー名・ID も含める場合

`FinalResultSnapshot` にプレイヤー情報を含めて渡します。

```ruby
final_snapshot = Mahjong::Snapshots::FinalResultSnapshot.new(
  scores: { 0 => 35_000, 1 => 28_000, 2 => 22_000, 3 => 15_000 },
  players_by_seat: {
    0 => { player_id: 10, name: "Alice" },
    1 => { player_id: 11, name: "Bob" },
    2 => { player_id: 12, name: "Carol" },
    3 => { player_id: 13, name: "Dave" }
  }
)

final_results = RiichiEngine::API.calculate_final_results(
  final_result_snapshot: final_snapshot,
  rule:                  rule
)
```

---

## 8. キャッシュから RoundState を復元する

`RoundState` は JSON にシリアライズできます。Redis 等のキャッシュに保存し、後から復元することで  
サーバーサイドで状態を保持せずに局を進行させられます。

```ruby
# 保存側
json = state.to_json
cache.set("round:#{round_id}", json)

# 復元側
json   = cache.get("round:#{round_id}")
state  = RiichiEngine::API.deserialize_round_state(json)
```

---

## 9. host app 側の責務分担

`riichi_engine` と host app の責務の分担は以下の通りです。

### riichi_engine が担うもの

- 局進行（自摸・打牌・鳴き・カン）
- 和了判定・役判定
- 点数計算・順位計算

### host app が担うもの

- スナップショットの生成（ActiveRecord モデル → Snapshot）
- DB 保存・更新
- ActionCable / Turbo 配信
- Job enqueue
- キャッシュへの `RoundState` 保存・復元

詳細は [Adapter 契約](adapter_contract.md) を参照してください。
