# Keep the discard with the most acceptance in the normal CPU

Branch: `fix/cpu-discard-ukeire`

## What is wrong

`TileEvaluator.evaluate_all_discards` gives, per discard, the ukeire of the
hand left after it. `DahaiSelector.select_normal` sorts the candidates of the
best shanten by that ukeire *ascending* and takes the first: the CPU keeps the
shape that accepts the fewest tiles (a kanchan over a ryanmen). `select_hard`
falls back to `select_normal` near tenpai, while `select_defensive` already
sorts by `-ukeire`.

## Reproduce

`123m 456p 789s 22m 34s 6s` + any: cutting 6s (or 9s) leaves 2s-5s (8 tiles),
cutting 3s leaves the 5s kanchan (4); level 2 and 3 cut 3s. Specs in
`dahai_selector_spec.rb`. In 40 hanchan of four normal CPUs (driven by a
host that supplies the riichi discard of `fix/riichi-discard`), 341 of 452
rounds (75 %) ended in an exhaustive draw; with this fix (and the other
fixes), 85 of 488 (17 %).

## Fix

Sort by ukeire descending; the danger score and the tile name still break ties.
The easy level is left as it is (it prefers terminals and honors first; it may
be meant to be weak).

## Compatibility

The normal and hard CPUs play differently (better). No API change.

---

CPU (normal、と hard の多く) が受け入れのいちばん少ない形を残していた (並べ替えが昇順)。受け入れの多い方を残すようにした。easy は変えていない。
