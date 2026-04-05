# RiichiEngine API Reference

`RiichiEngine::API` は host app や adapter 層から `riichi_engine` を呼ぶための公開入口。

`Mahjong::*` 配下の domain object を直接使うことはできるが、局進行や和了評価の入口は原則 `RiichiEngine::API` を使う。

- 公開境界ポリシー: `docs/public_api_policy.md`
- host app 契約: `docs/adapter_contract.md`

## Common Types

### Rule

```ruby
rule = Mahjong::Config::RuleConfig.new
```

### Snapshots

```ruby
Mahjong::Snapshots::GameSetupSnapshot
Mahjong::Snapshots::GameProgressSnapshot
Mahjong::Snapshots::FinalResultSnapshot
Mahjong::Snapshots::WinEvaluationSnapshot
```

### State

```ruby
Mahjong::State::RoundState
```

## Methods

### `setup_round(game_snapshot:, rule:, seed: nil)`

局の初期状態を構築する。

引数:

- `game_snapshot`: `Mahjong::Snapshots::GameSetupSnapshot`
- `rule`: `Mahjong::Config::RuleConfig`
- `seed`: `String | nil`

返り値:

- `Mahjong::State::RoundState`

### `apply_round_action(state:, action:, rule:)`

局中アクションを state に適用する。

引数:

- `state`: `Mahjong::State::RoundState`
- `action`: `Hash`
- `rule`: `Mahjong::Config::RuleConfig`

代表的な `action`:

```ruby
{ type: :tsumo }
{ type: :dahai, seat: 0, tile: "5m" }
{ type: :riichi, seat: 0, tile: "3z" }
{ type: :pon, seat: 1, tiles: %w[5m 5m] }
{ type: :chi, seat: 1, tiles: %w[4m 6m] }
{ type: :ankan, seat: 0, tile: "5m" }
{ type: :kakan, seat: 0, tile: "5m" }
{ type: :daiminkan, seat: 1 }
{ type: :tsumo_agari, seat: 0 }
{ type: :ron_agari, seat: 1 }
{ type: :skip, seat: 2 }
{ type: :kyuushu_kyuuhai, seat: 0 }
```

返り値:

- `Mahjong::Results::RoundFlowResult`

例外:

- `RiichiEngine::API::InvalidActionError`
- `RiichiEngine::API::EngineError`

### `available_round_actions(state:, seat:, rule:)`

指定 seat に対して現在選択可能な局中アクション一覧を返す。

返り値:

- `Array<Hash>`

### `resolve_pending_action(pending_actions)`

鳴き競合時の優先順位を解決する。

引数:

- `pending_actions`: `Hash{Integer => Array<Hash>}`

返り値:

- `Hash | nil`

### `judge_next_game_round(progress_snapshot:, round_end_info:, rule:)`

局終了後に次局へ進むかゲーム終了かを判定する。

引数:

- `progress_snapshot`: `Mahjong::Snapshots::GameProgressSnapshot`
- `round_end_info`: `Mahjong::Results::RoundEndInfo` または同等の `Hash`
- `rule`: `Mahjong::Config::RuleConfig`

返り値:

- `Mahjong::Results::GameFlowResult`

### `calculate_final_results(final_result_snapshot:, rule:)`

プレイヤー情報付きの最終結果を返す。

引数:

- `final_result_snapshot`: `Mahjong::Snapshots::FinalResultSnapshot`
- `rule`: `Mahjong::Config::RuleConfig`

返り値:

- `Array<Mahjong::Results::FinalResult>`

### `calculate_ranked_results(scores:, rule:)`

順位と point 計算だけを行う。

引数:

- `scores`: `Hash{Integer => Integer}`
- `rule`: `Mahjong::Config::RuleConfig`

返り値:

- `Array<Mahjong::Results::FinalResult>`

### `calculate_tenpai_payments(tenpai_seats)`

流局時のノーテン罰符を計算する。

引数:

- `tenpai_seats`: `Array<Integer>`

返り値:

- `Hash{Integer => Integer}`

### `tenpai_seats(state)`

現在の `RoundState` からテンパイ seat 一覧を返す。

返り値:

- `Array<Integer>`

### `evaluate_win(state:, seat:, agari_type:, agari_tile:, rule:, extra_flags:, snapshot:)`

和了評価を行い、役情報と点数計算結果を返す。

引数:

- `state`: `Mahjong::State::RoundState`
- `seat`: `Integer`
- `agari_type`: `:tsumo | :ron`
- `agari_tile`: `Mahjong::Tiles::Tile | String`
- `rule`: `Mahjong::Config::RuleConfig`
- `extra_flags`: `Hash`
- `snapshot`: `Mahjong::Snapshots::WinEvaluationSnapshot`

返り値:

- `[winner_info, score_result]`

`winner_info` は役一覧や符翻を含む `Hash`、`score_result` は `Mahjong::Scoring::ValueObjects::ScoreResult`

### `agari?(tiles_34)`

34 形式の牌配列が和了形かどうかを返す。

返り値:

- `true | false`

### `deserialize_round_state(json)`

シリアライズ済み `RoundState` JSON から state を復元する。

返り値:

- `Mahjong::State::RoundState`

## Error Aliases

adapter 層は以下を rescue すればよい。

```ruby
RiichiEngine::API::InvalidActionError
RiichiEngine::API::EngineError
```
