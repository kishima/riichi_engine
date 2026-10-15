# evaluate_win のドラを、表示牌の次の牌で数える

ブランチ: `fix/dora-indicators`（`main` = v0.1.0 から）

## 何が誤りか

`WinEvaluator.evaluate`（`RiichiEngine::API.evaluate_win` の中身）は、`state.dora_hyouji` と
`state.uradora_hyouji`（ドラ表示牌そのもの）を役の文脈の `dora_tiles`・`uradora_tiles` に渡しています。
そのため和了の評価では、表示牌の次の牌ではなく表示牌そのものがドラとして数えられます。
`RoundFlow.can_agari?` は正しく `state.wanpai.dora_tiles`（次の牌）を使っているので、2 か所の判定が食い違っています。

## 再現

手牌 `234m 67m 345p 678s 22p`、5m でロン、ドラ表示牌 1m: 手に 2m が 1 枚あるのでドラ 1 のはずが、
`evaluate_win` はドラなしと返します。表示牌が 2p なら、3p の 1 枚でドラ 1 のはずが、2p 2 枚でドラ 2 と返します。
新しい spec `spec/mahjong/scoring/evaluators/win_evaluator_spec.rb` に両方と、裏ドラの同じ場合を入れました。

## 直し

役の文脈を作る前に、表示牌を次の牌に置き換えます（`Wanpai#dora_tiles` と同じく `Tile#next_tile_notation`）。

## 互換性

ドラのある和了はすべて点数が変わります（正しい値になります）。API の変更はありません。
`evaluate_win` を呼ぶ前に `state.dora_hyouji` へドラそのものを入れて回避していた host は、それをやめる必要があります。

---

和了の評価（`evaluate_win`）がドラ表示牌そのものをドラとして数えていた（裏ドラも同じ）。`can_agari?` と同じく表示牌の次の牌で数えるようにした。
