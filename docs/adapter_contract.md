# RiichiEngine Adapter Contract

host app 側は副作用と永続化を持ち、`riichi_engine` 側は pure domain を持つ。この境界で adapter が担う責務を固定する。

## Adapter Responsibilities

host app 側 adapter が担うもの:

- `RuleConfig` の生成
- ActiveRecord model から snapshot の生成
- `RoundState` の cache 保存・復元・削除
- `round_end_info` の正規化
- 最終結果への表示情報付与
- CPU レベルに応じた AI インスタンス選択

`riichi_engine` 側に持ち込まないもの:

- ActiveRecord
- ActionCable / Turbo
- ActiveJob
- cache backend
- logger
- request/session/user context

## Concrete Adapters In Host App

現在の host app 側 adapter:

- `MahjongAdapter::RuleBuilder`
- `MahjongAdapter::SnapshotBuilder`
- `MahjongAdapter::RoundEndInfoBuilder`
- `MahjongAdapter::FinalResultBuilder`
- `MahjongAdapter::RoundStateCache`
- `MahjongAdapter::CpuAiFactory`

## SnapshotBuilder Contract

`SnapshotBuilder` は ActiveRecord を pure snapshot へ落とす。

生成対象:

- `Mahjong::Snapshots::GameSetupSnapshot`
- `Mahjong::Snapshots::GameProgressSnapshot`
- `Mahjong::Snapshots::FinalResultSnapshot`
- `Mahjong::Snapshots::WinEvaluationSnapshot`

制約:

- snapshot には AR object を入れない
- key は seat 基準で安定させる
- score や bakaze などの値は domain がそのまま読める形にする

## RuleBuilder Contract

`RuleBuilder` は host app の DB 設定や room/game 設定から `Mahjong::Config::RuleConfig` を作る。

制約:

- `RuleConfig` に渡すのは plain Ruby `Hash`
- adapter 側で key 正規化を意識しなくてよい
- room/game model 自体を gem 側へ渡さない

## RoundStateCache Contract

`RoundStateCache` は `RoundState` の serialize / deserialize と cache key を管理する。

制約:

- cache backend の詳細は adapter 側で隠蔽する
- gem 側には `json` 文字列だけを渡す
- host app 側が version 管理や cache invalidation を担う

## RoundEndInfoBuilder Contract

`RoundEndInfoBuilder` は host app 文脈の局終了情報を `Mahjong::Results::RoundEndInfo` に正規化する。

担当:

- 流局時のテンパイ seat 算出
- ノーテン罰符算出のための API 呼び出し
- 和了評価のための snapshot 組み立て

## FinalResultBuilder Contract

`FinalResultBuilder` は順位計算後の `FinalResult` に host app 表示情報を合成する。

担当:

- `player_id`
- `name`
- app 固有の表示順・装飾に必要な補足情報

## Service Layer Rule

service/job は次を守る。

- gem 呼び出しは `RiichiEngine::API` を経由する
- adapter 生成物だけを API に渡す
- DB 保存、job enqueue、broadcast は service/job 側で行う
- gem の内部 namespace を直接 stub / mock しない
