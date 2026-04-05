# 公開 API ポリシー

`riichi_engine` では、安定性を保証する公開 API と、内部実装として扱う非公開 API を明確に分けています。

host app が直接呼んでよい範囲を限定することで、gem 内部の自由な整理・リファクタリングを可能にします。

---

## 安定 API（Stable Public Surface）

以下は host app が直接利用してよい、安定性を保証する API です。

### エントリポイント

```ruby
RiichiEngine::API
```

局進行・和了評価・点数計算はすべてここを通してください。

### 例外

```ruby
RiichiEngine::API::InvalidActionError
RiichiEngine::API::EngineError
```

### 値オブジェクト・設定

```ruby
Mahjong::Config::RuleConfig     # ルール設定
Mahjong::Snapshots::*           # 局情報を gem へ渡すためのスナップショット群
Mahjong::State::RoundState      # 局状態（API の入出力として使う）
```

---

## 準公開 API（Conditionally Public Domain Objects）

以下は `RiichiEngine::API` の入出力として現実的に参照することがあるため、事実上 public 扱いとします。  
ただし、`RiichiEngine::API` の結果として受け取る形でのみ使用し、直接インスタンスを生成しないでください。

```ruby
Mahjong::Tiles::Tile
Mahjong::State::Hand
Mahjong::Results::RoundFlowResult
Mahjong::Results::GameFlowResult
Mahjong::Results::FinalResult
Mahjong::Results::RoundEndInfo
Mahjong::Scoring::ValueObjects::ScoreResult
```

この層は大きく壊さない前提ですが、`RiichiEngine::API` ほど強い安定契約はありません。

---

## 内部 API（Internal Surface）

以下は host app から直接参照しないでください。  
gem の内部責務整理・namespace 再編・最適化のために予告なく変更することがあります。

```ruby
Mahjong::Flow::*                          # 局・ゲーム進行の内部処理
Mahjong::Scoring::*                       # 役判定・点数計算の実装詳細
Mahjong::Cpu::*                           # CPU AI の実装
Mahjong::Errors::*                        # EngineError / InvalidActionError 以外
```

---

## host app が守るべきルール

1. 局進行は `RiichiEngine::API` を経由する
2. 和了評価は `RiichiEngine::API` を経由する
3. 順位計算は `RiichiEngine::API` を経由する
4. スナップショット生成・永続化変換は host app の adapter が担う
5. `Mahjong::Flow::*` や `Mahjong::Scoring::Judges::*` を service/job から直接呼ばない

---

## Breaking Change ポリシー

### Breaking Change とみなすもの（事前告知・メジャーバージョンアップが必要）

- `RiichiEngine::API` のメソッド削除
- `RiichiEngine::API` の必須引数変更
- `Mahjong::Snapshots::*` の必須フィールド変更
- `Mahjong::Config::RuleConfig` の既存キーの意味変更

### Breaking Change とみなさないもの

- 内部 namespace の移動・名前変更
- `Mahjong::Flow::*` / `Mahjong::Scoring::*` の整理
- `RiichiEngine::API` を通じた結果が同じである範囲の内部最適化
