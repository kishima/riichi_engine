# riichi_engine

Pure Ruby 実装のリーチ麻雀エンジン Gem です。

局進行・和了判定・役判定・点数計算・順位計算を Rails・ActiveRecord 非依存で提供します。  
host app から `RiichiEngine::API` を呼ぶだけで、麻雀の完全なドメインロジックを利用できます。

---

## 機能

| カテゴリ | 内容 |
|---|---|
| 局進行管理 | 牌山構築・配牌・自摸・打牌・鳴き（ポン/チー/カン）・リーチ処理 |
| 和了判定 | 通常和了形・七対子・国士無双 |
| 役判定 | 一般役から役満まで全役対応 |
| 点数計算 | 符・翻の計算、基本点・各プレイヤーへの支払い点算出 |
| 順位計算 | ウマ・オカを含む最終スコア計算 |
| CPU AI | Easy / Normal / Hard の3段階（host app 側での切り替え対応） |

---

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [概念・用語集](docs/concepts.md) | 牌記法・麻雀用語・アクション種別の解説 |
| [使用例](docs/usage_examples.md) | 局開始〜終了までのコード例 |
| [局ステートマシン](docs/state_machine.md) | フェーズ遷移・アクション優先順位・特殊シーケンスの解説 |
| [API リファレンス](docs/api_reference.md) | 公開メソッドの詳細仕様 |
| [公開 API ポリシー](docs/public_api_policy.md) | 安定保証の範囲と方針 |
| [Adapter 契約](docs/adapter_contract.md) | host app と gem の責務境界 |

---

## インストール

vendor gem として組み込む場合は Gemfile に追加します：

```ruby
gem "riichi_engine", path: "vendor/gems/riichi_engine"
```

---

## クイックスタート

### 1. 局を開始する

`RuleConfig` を作成し、局の初期情報を `GameSetupSnapshot` に詰めて `setup_round` を呼びます。

```ruby
rule = Mahjong::Config::RuleConfig.new  # デフォルトルール（東南戦・25000点持ち等）

snapshot = Mahjong::Snapshots::GameSetupSnapshot.new(
  bakaze:    "ton",  # 東場
  kyoku:     1,      # 1局目
  honba:     0,
  kyoutaku:  0,
  oya_index: 0,      # seat 0 が親
  scores: { 0 => 25_000, 1 => 25_000, 2 => 25_000, 3 => 25_000 }
)

state = RiichiEngine::API.setup_round(
  game_snapshot: snapshot,
  rule:          rule,
  seed:          "round-001"  # 牌山シード（省略可）
)
```

### 2. 自摸・打牌を進める

アクションを順に `apply_round_action` へ渡すことで局を進行させます。  
選択可能なアクション一覧は `available_round_actions` で取得できます。

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

`result` は `Mahjong::Results::RoundFlowResult` です。  
`result.round_end?` が `true` のとき局が終了しており、`result.round_end_info` に終了情報が入ります。

### 3. 局終了後に次局かゲーム終了かを判定する

```ruby
flow_result = RiichiEngine::API.judge_next_game_round(
  progress_snapshot: progress_snapshot,
  round_end_info:    result.round_end_info,
  rule:              rule
)

# flow_result.next_round? => true なら次局へ
# flow_result.game_end?   => true ならゲーム終了
```

---

## エラー

エンジンが発生させる例外は2種類です。host app 側の adapter で rescue してください。

```ruby
RiichiEngine::API::InvalidActionError  # 不正なアクション（不正な打牌・存在しない鳴き等）
RiichiEngine::API::EngineError         # エンジン内部エラー
```

---

## ルール設定

`RuleConfig.new` にハッシュを渡すことで細かい設定が可能です。

```ruby
rule = Mahjong::Config::RuleConfig.new(
  "game_type"      => "hanchan",  # "hanchan"（東南戦）or "tonpuu"（東風戦）
  "initial_score"  => 25_000,
  "uma"            => [20_000, 10_000, -10_000, -20_000],
  "kuitan"         => true,       # 食い断あり
  "double_ron"     => true,       # ダブロン
  "tobi"           => true        # トビあり
)
```

設定項目の詳細は [API リファレンス](docs/api_reference.md#ruleconfigの設定項目) を参照してください。

---

## テスト実行

```bash
bundle install --local
bundle exec rspec
```

---

## ライセンス

MIT
