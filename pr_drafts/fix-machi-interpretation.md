# Evaluate every wait the winning tile can complete

Branch: `fix/machi-interpretation`

## What is wrong

For one decomposition of a winning hand, `MachiJudge` returns only the first
wait it meets (the pair, then the sets in order). The winning tile can belong
to more than one of them, and a hand is scored with the most favourable
reading:

- `123s 345m 123p 345p 55m`, tsumo 5m: the 5m is a tanki (pair 55m) or a
  ryanmen (34m + 5m). As ryanmen the hand has pinfu (20 fu); the engine scores
  the tanki (30 fu, no pinfu).
- `567p 123s 678p 444z 99s`, tsumo 7p: a ryanmen (56p) or a kanchan (68p);
  the kanchan gives 40 fu, the engine scores 30.

## Reproduce

Specs in `machi_judge_spec.rb` and `win_evaluator_spec.rb`.

## Fix

`MachiJudge.regular_machi_types` returns every wait per decomposition;
`WinEvaluator` and `RoundFlow.can_agari?` try each (`WinEvaluator` already
keeps the best score across decompositions). `find_machi` may now return more
than one result for the same tile and form; `tenpai?` and
`machi_tile_indices` are unchanged.

## Compatibility

Some wins score higher (pinfu found, higher fu). Found by the comparison with
the Python `mahjong` package.

---

和了牌が単騎にも両面にも (両面にも嵌張にも) 取れるとき、最初の 1 つしか見ず、平和や高い符を逃していた。取り得る待ちを全部試して高い方を採る。
