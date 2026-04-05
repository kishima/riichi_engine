# riichi_engine

Pure Ruby の riichi mahjong ドメインロジックを切り出した gem。

## Scope

- `Mahjong::*` namespace の pure domain を提供する
- 入力は rule / snapshot / state / plain Ruby object に限定する
- Rails, ActiveRecord, ActiveJob, ActionCable, cache persistence は持ち込まない

## Public API

Rails app や adapter 層からの入口は `RiichiEngine::API` を前提にする。

- 詳細仕様: `docs/api_reference.md`
- 具体例: `docs/usage_examples.md`
- 公開境界: `docs/public_api_policy.md`
- adapter 契約: `docs/adapter_contract.md`
- versioning: `docs/versioning_policy.md`
- release 手順: `docs/release_process.md`

```ruby
rule = Mahjong::Config::RuleConfig.new

RiichiEngine::API.setup_round(game_snapshot:, rule:, seed:)
RiichiEngine::API.apply_round_action(state:, action:, rule:)
RiichiEngine::API.available_round_actions(state:, seat:, rule:)
RiichiEngine::API.resolve_pending_action(pending_actions)

RiichiEngine::API.judge_next_game_round(progress_snapshot:, round_end_info:, rule:)
RiichiEngine::API.calculate_final_results(final_result_snapshot:, rule:)
RiichiEngine::API.calculate_ranked_results(scores:, rule:)
RiichiEngine::API.calculate_tenpai_payments(tenpai_seats)
RiichiEngine::API.tenpai_seats(state)

RiichiEngine::API.evaluate_win(state:, seat:, agari_type:, agari_tile:, rule:, extra_flags:, snapshot:)
RiichiEngine::API.agari?(tiles_34)
RiichiEngine::API.deserialize_round_state(json)
```

例外 alias:

```ruby
RiichiEngine::API::InvalidActionError
RiichiEngine::API::EngineError
```

## Snapshot Types

```ruby
Mahjong::Snapshots::GameSetupSnapshot
Mahjong::Snapshots::GameProgressSnapshot
Mahjong::Snapshots::FinalResultSnapshot
Mahjong::Snapshots::WinEvaluationSnapshot
```

表示用の `player_id` / `name` や DB 永続化都合の情報は host app 側 adapter で合成する。

## Standalone Test

gem 単体で実行できる。

```bash
bundle install --local
bundle exec rspec
```

この repo 内では `spec/support` を gem 側に持っていて、host app の `rails_helper` には依存しない。

## RubyGems Publish

GitHub Actions の `release.yml` は `v*` tag push で動き、RubyGems publish まで実行する。

必要な repository secret:

- `RUBYGEMS_API_KEY`

公開前に version と `CHANGELOG.md` を更新すること。

## Host App Boundary

host app 側に残す責務:

- ActiveRecord model
- Service orchestration
- ActiveJob
- ActionCable / Turbo broadcast
- Cache persistence
- adapter object (`RuleBuilder`, `SnapshotBuilder`, `RoundEndInfoBuilder`, `FinalResultBuilder`, `RoundStateCache`)

詳細は `docs/adapter_contract.md` を参照。

## Development Policy

- public API は `RiichiEngine::API` を主入口にする
- gem 内では ActiveSupport 拡張に依存しない
- domain namespace (`Mahjong::*`) と配布単位 (`RiichiEngine`) は分けて扱う
- public / internal 境界は `docs/public_api_policy.md` に従う

## Status

現時点では internal gem として利用しているが、別 repository 化と公開を前提に整備を進めている。
