# Count four identical sequences as ryanpeiko

Branch: `fix/ryanpeiko-four-sequences`

## What is wrong

`Iipeiko.count_shuntsu_pairs` counts the sequences that occur at least twice,
so four copies of one sequence (`678p 678p 678p 678p 22s`) make one pair: the
hand gets iipeiko instead of ryanpeiko, and as iipeiko it loses to the reading
with three concealed triplets (666p 777p 888p 678p).

## Reproduce

Spec "同じ順子 4 つも二盃口と判定する" in `pattern_yaku_spec.rb`.

## Fix

Count pairs: `c / 2` per sequence. Three copies still make one pair (iipeiko;
spec added).

## Rule

Four identical sequences are ryanpeiko (Tenhou, M-League).

## Compatibility

Only such hands change. Found by the comparison with the Python `mahjong`
package.

---

同じ順子 4 つの手が二盃口にならず一盃口になっていた。組の数え方を直した。
