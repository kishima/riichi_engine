# RiichiEngine Public API Policy

`riichi_engine` では、公開して安定性を約束する面と、内部実装として扱う面を分ける。

## Stable Public Surface

原則として、host app や外部利用者が直接呼んでよいのは次だけ。

- `RiichiEngine::API`
- `RiichiEngine::API::InvalidActionError`
- `RiichiEngine::API::EngineError`
- `Mahjong::Config::RuleConfig`
- `Mahjong::Snapshots::*`
- `Mahjong::State::RoundState`

理由:

- app から core へ入る経路を限定したい
- 内部 namespace の再編をしやすくしたい
- 互換性を守る面を小さく保ちたい

## Conditionally Public Domain Objects

以下は API 入出力として現実的に触ることがあるので、事実上 public 扱いする。ただし、生成や利用は `RiichiEngine::API` の前後に限定する。

- `Mahjong::Tiles::Tile`
- `Mahjong::State::Hand`
- `Mahjong::Results::RoundFlowResult`
- `Mahjong::Results::GameFlowResult`
- `Mahjong::Results::FinalResult`
- `Mahjong::Results::RoundEndInfo`
- `Mahjong::Scoring::ValueObjects::ScoreResult`

この層は大きく壊さない前提だが、`RiichiEngine::API` ほど強い安定契約は置かない。

## Internal Surface

以下は internal 扱いで、host app から直接参照しない前提。

- `Mahjong::Flow::*`
- `Mahjong::Scoring::*` の judge / calculator / yaku 実装詳細
- `Mahjong::Cpu::*`
- `Mahjong::Results::*` の内部計算詳細
- `Mahjong::Errors::*` のうち facade alias で公開していないもの

これらは gem 内部の責務整理、namespace 再編、最適化のために変更しうる。

## Host App Rule

host app からの原則:

- 局進行は `RiichiEngine::API` を使う
- 和了評価は `RiichiEngine::API` を使う
- 順位計算は `RiichiEngine::API` を使う
- snapshot / rule / persistence 変換は host app adapter が持つ
- `Mahjong::Flow::*` や `Mahjong::Scoring::Judges::*` を service/job から直接呼ばない

## Breaking Change Policy

breaking change とみなすもの:

- `RiichiEngine::API` のメソッド削除
- `RiichiEngine::API` の必須引数変更
- `Mahjong::Snapshots::*` の必須フィールド変更
- `Mahjong::Config::RuleConfig` の既存キー意味変更

breaking change とみなさないもの:

- internal namespace の移動
- judge / calculator / cpu 実装の整理
- `RiichiEngine::API` を通じた結果が同じである範囲の内部最適化
