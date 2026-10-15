# 文書の game_type "tonpuu" を受け付ける

ブランチ: `fix/tonpuu-game-type`

## 何が誤りか

README と `docs/api_reference.md` は東風戦を `"tonpuu"` と書いていますが、`GameFlow` は `"tonpuusen"` しか
知りません。文書の値では `should_end_game?` が `false` に落ちてゲームが終わらず、オーラスの親の和了でも終わりません。

## 再現

`RuleConfig.new("game_type" => "tonpuu")` で東 4 局を子が和了ると、`judge_next` がゲーム終了ではなく
次局（南 1 局）を返します。`game_flow_spec.rb` の spec。

## 直し

どちらの名前も東風戦として扱います。文書は `"tonpuu"` のままにし、`"tonpuusen"` も同じと書きました。

## 互換性

`"tonpuusen"` は今までどおりです。知らない `game_type` が終わらないのはこのブランチでは変えていません
（`fix/unknown-game-type` で弾くようにします）。

---

文書の `"tonpuu"` ではゲームが終わらなかった（コードは `"tonpuusen"` しか知らない）。両方を東風戦として扱う。
