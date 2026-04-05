# RiichiEngine Usage Examples

## 1. 局開始

```ruby
rule = Mahjong::Config::RuleConfig.new

snapshot = Mahjong::Snapshots::GameSetupSnapshot.new(
  bakaze: "ton",
  kyoku: 1,
  honba: 0,
  kyoutaku: 0,
  oya_index: 0,
  scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
)

state = RiichiEngine::API.setup_round(
  game_snapshot: snapshot,
  rule: rule,
  seed: "round-001"
)
```

## 2. 自摸して打牌する

```ruby
RiichiEngine::API.apply_round_action(
  state: state,
  action: { type: :tsumo },
  rule: rule
)

actions = RiichiEngine::API.available_round_actions(
  state: state,
  seat: state.current_seat,
  rule: rule
)

dahai = actions.find { |action| action[:type] == :dahai }

result = RiichiEngine::API.apply_round_action(
  state: state,
  action: { type: :dahai, seat: state.current_seat, tile: dahai[:tile] },
  rule: rule
)
```

`result` は `Mahjong::Results::RoundFlowResult` で、`events`, `round_end`, `round_end_info` を持つ。

## 3. 鳴き競合の解決

```ruby
resolved = RiichiEngine::API.resolve_pending_action(state.pending_actions)

if resolved
  RiichiEngine::API.apply_round_action(
    state: state,
    action: resolved,
    rule: rule
  )
end
```

## 4. 流局時のテンパイ料計算

```ruby
tenpai = RiichiEngine::API.tenpai_seats(state)
payments = RiichiEngine::API.calculate_tenpai_payments(tenpai)
# => { 0 => 1500, 1 => -1500, 2 => 1500, 3 => -1500 }
```

## 5. 和了評価

```ruby
win_snapshot = Mahjong::Snapshots::WinEvaluationSnapshot.new(
  bakaze: state.bakaze,
  oya_index: state.oya_seat,
  honba: state.honba,
  kyoutaku: state.kyoutaku,
  jikaze: "ton"
)

winner_info, score_result = RiichiEngine::API.evaluate_win(
  state: state,
  seat: 0,
  agari_type: :tsumo,
  agari_tile: state.last_tsumo,
  rule: rule,
  extra_flags: {},
  snapshot: win_snapshot
)
```

`winner_info` には役・翻・符などが入り、`score_result.payments` から支払い額を取れる。

## 6. 局終了後の次局判定

```ruby
progress_snapshot = Mahjong::Snapshots::GameProgressSnapshot.new(
  bakaze: "ton",
  kyoku: 1,
  honba: 0,
  kyoutaku: 0,
  oya_index: 0,
  scores: { 0 => 24_000, 1 => 26_000, 2 => 25_000, 3 => 25_000 }
)

round_end_info = Mahjong::Results::RoundEndInfo.new(
  result_type: :ron,
  winners: [{ seat: 1 }],
  losers: [{ seat: 0 }],
  tenpai_seats: [],
  draw_reason: nil,
  score_changes: {}
)

flow_result = RiichiEngine::API.judge_next_game_round(
  progress_snapshot: progress_snapshot,
  round_end_info: round_end_info,
  rule: rule
)
```

## 7. 最終順位計算

```ruby
ranked = RiichiEngine::API.calculate_ranked_results(
  scores: { 0 => 35_000, 1 => 28_000, 2 => 22_000, 3 => 15_000 },
  rule: rule
)
```

表示情報込みで必要なら `FinalResultSnapshot` を使う。

```ruby
final_snapshot = Mahjong::Snapshots::FinalResultSnapshot.new(
  scores: { 0 => 35_000, 1 => 28_000, 2 => 22_000, 3 => 15_000 },
  players_by_seat: {
    0 => { player_id: 10, name: "A" },
    1 => { player_id: 11, name: "B" },
    2 => { player_id: 12, name: "C" },
    3 => { player_id: 13, name: "D" }
  }
)

final_results = RiichiEngine::API.calculate_final_results(
  final_result_snapshot: final_snapshot,
  rule: rule
)
```

## 8. Cache から RoundState を復元

```ruby
restored = RiichiEngine::API.deserialize_round_state(json)
```

## 9. Host App での責務分担

`riichi_engine` 側:

- 局進行
- 和了判定
- 役判定
- 点数計算
- 順位計算

host app 側:

- snapshot 作成
- DB 保存
- ActionCable / Turbo 配信
- Job enqueue
- cache 保存
