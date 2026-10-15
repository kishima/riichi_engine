# 知らない game_type は、終わらないゲームにせず弾く

ブランチ: `fix/unknown-game-type`（`fix/tonpuu-game-type` の上）

## 何が誤りか

`GameFlow.should_end_game?` は知らない `game_type` に `false` を返します。書き間違えた `game_type`
（`"hanchan"` のつもりの `"hanchan "` や `"tonnan"` など）ではゲームが終わらず、西場・北場を過ぎても局が続きます。
`RuleConfig.new` は値を見ないので、間違いに気づく場所がありません。

## 再現

- `rule_config_spec.rb`: `RuleConfig.new("game_type" => "tonnan")` が `EngineError` になること、`"hanchan"`・
  `"tonpuu"`・`"tonpuusen"` は受けること
- `game_flow_spec.rb`: 知らない `game_type` の rule では `judge_next` が `EngineError` になること

## 直し

- `RuleConfig::GAME_TYPES = %w[hanchan tonpuu tonpuusen]` を足し、`RuleConfig.new` はそれ以外の `game_type` で
  `Mahjong::Errors::EngineError`（`RiichiEngine::API::EngineError`）を上げます。
- `should_end_game?` も知らない `game_type` では続けずに `EngineError` を上げます。
- `api_reference.md` の表に書きました。

`fix/tonpuu-game-type`（`"tonpuu"` を東風戦として扱う）の上に作ってあります。

## 互換性

`game_type` が 3 つの値のどれかなら変わりません。それ以外の値はこれまで終わらないゲームになっていたので、
弾かれて困る使い方は無いと考えます。

---

知らない `game_type` ではゲームが終わらず局が続いていた。`RuleConfig.new` で `EngineError` にする。
