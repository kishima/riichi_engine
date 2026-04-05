# Adapter 契約

`riichi_engine` は pure Ruby のドメインロジックのみを持ち、副作用・永続化は一切持ちません。  
host app 側の「adapter 層」がこの境界で両者をつなぐ役割を担います。

---

## 責務の境界

### riichi_engine 側が持つもの

- 局進行ロジック
- 和了判定・役判定
- 点数計算・順位計算
- CPU AI の判断ロジック

### host app 側が持つもの（gem に持ち込まないもの）

- ActiveRecord
- ActionCable / Turbo
- ActiveJob
- キャッシュバックエンド
- ロガー
- リクエスト / セッション / ユーザーコンテキスト

---

## host app 側 adapter の役割

host app には以下の adapter を実装します。各 adapter の責務を分けることで、gem のバージョンアップ時の修正箇所を局所化できます。

| Adapter | 責務 |
|---|---|
| `MahjongAdapter::RuleBuilder` | DB / room 設定から `RuleConfig` を生成する |
| `MahjongAdapter::SnapshotBuilder` | ActiveRecord モデルから各種 Snapshot を生成する |
| `MahjongAdapter::RoundEndInfoBuilder` | 局終了情報を `RoundEndInfo` に正規化する |
| `MahjongAdapter::FinalResultBuilder` | 最終結果にプレイヤー表示情報を合成する |
| `MahjongAdapter::RoundStateCache` | `RoundState` のキャッシュ保存・復元・削除を管理する |
| `MahjongAdapter::CpuAiFactory` | CPU レベルに応じた AI インスタンスを選択する |

---

## SnapshotBuilder の契約

ActiveRecord オブジェクトを pure な Snapshot へ変換します。

**生成対象：**

```ruby
Mahjong::Snapshots::GameSetupSnapshot      # 局開始時
Mahjong::Snapshots::GameProgressSnapshot   # 局終了後の進行判定時
Mahjong::Snapshots::FinalResultSnapshot    # ゲーム終了時の最終結果
Mahjong::Snapshots::WinEvaluationSnapshot  # 和了評価時
```

**制約：**

- Snapshot の値に ActiveRecord オブジェクトを含めない
- key は seat 番号基準で統一する
- `score` や `bakaze` などの値はドメイン側がそのまま読める形にする

---

## RuleBuilder の契約

host app の DB 設定や room/game 設定から `Mahjong::Config::RuleConfig` を作成します。

**制約：**

- `RuleConfig` に渡すのは plain Ruby の `Hash`（ActiveRecord モデルを渡さない）
- key の正規化は `RuleConfig` 側で行うため、adapter 側で意識しなくてよい

```ruby
# OK: Hash で渡す
RuleConfig.new("kuitan" => room.rule_kuitan, "uma" => room.rule_uma)

# NG: モデルを直接渡す
RuleConfig.new(room)
```

---

## RoundStateCache の契約

`RoundState` のシリアライズ・デシリアライズとキャッシュキーを管理します。

**制約：**

- キャッシュバックエンドの詳細は adapter 側で隠蔽する
- gem 側へは `json` 文字列のみを渡す
- バージョン管理・キャッシュ失効（invalidation）は host app 側で担う

```ruby
# 保存
json = state.to_json
RoundStateCache.save(round_id: round.id, json:)

# 復元
json  = RoundStateCache.load(round_id: round.id)
state = RiichiEngine::API.deserialize_round_state(json)
```

---

## RoundEndInfoBuilder の契約

局終了時の host app 文脈の情報を `Mahjong::Results::RoundEndInfo` に正規化します。

**担当する処理：**

- 流局時のテンパイ座席の算出（`RiichiEngine::API.tenpai_seats` を呼ぶ）
- ノーテン罰符計算のための API 呼び出し
- 和了評価のためのスナップショット組み立て

---

## FinalResultBuilder の契約

`RiichiEngine::API.calculate_final_results` が返す `FinalResult` に、host app 固有の表示情報を合成します。

**担当する情報：**

- `player_id`
- プレイヤー名
- 表示順・装飾に必要な補足情報

---

## Service / Job 層のルール

service / job が守るべきこと：

1. gem の呼び出しは `RiichiEngine::API` を経由する
2. API に渡すオブジェクトは adapter が生成したものだけにする
3. DB 保存・Job enqueue・broadcast は service / job 側で行う
4. gem の内部 namespace（`Mahjong::Flow::*` など）を直接 stub / mock しない

```ruby
# OK: API 経由
result = RiichiEngine::API.apply_round_action(state:, action:, rule:)

# NG: 内部クラスを直接呼ぶ
result = Mahjong::Flow::Rounds::RoundFlow.apply_action(state:, action:, rule:)
```
