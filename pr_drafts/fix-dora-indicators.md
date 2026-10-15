# Count dora on the tiles the indicators point to in evaluate_win

Branch: `fix/dora-indicators` (from `main`, v0.1.0)

## What is wrong

`WinEvaluator.evaluate` (behind `RiichiEngine::API.evaluate_win`) passes
`state.dora_hyouji` and `state.uradora_hyouji` — the indicator tiles — to the
yaku context as `dora_tiles` / `uradora_tiles`. A win therefore counts the
indicators themselves as dora, not the tiles after them. `RoundFlow.can_agari?`
already does it right (`state.wanpai.dora_tiles`), so the two disagree.

## Reproduce

Hand `234m 67m 345p 678s 22p`, ron on 5m, dora indicator 1m: the hand holds
one 2m, so it has dora 1. `evaluate_win` reports no dora. With the indicator 2p
it reports dora 2 (the two 2p) instead of 1 (the 3p). The new spec
`spec/mahjong/scoring/evaluators/win_evaluator_spec.rb` has both, and the same
for uradora.

## Fix

Map the indicators to the next tile (`Tile#next_tile_notation`, as
`Wanpai#dora_tiles` does) before building the context.

## Compatibility

Scores change for every win with dora (they become correct). No API change.
A host that worked around this by putting the dora tiles into
`state.dora_hyouji` before calling `evaluate_win` must stop doing so.

---

和了の評価 (`evaluate_win`) がドラ表示牌そのものをドラとして数えていた (裏ドラも同じ)。`can_agari?` と同じく表示牌の次の牌で数えるようにした。
