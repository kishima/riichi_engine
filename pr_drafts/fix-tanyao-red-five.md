# Treat a red five as a simple tile in Tile#chunchan?

Branch: `fix/tanyao-red-five`

## What is wrong

`Tile#chunchan?` checks `number >= 2 && number <= 8`, and a red five has
`number == 0`. A hand with a red five never has tanyao (and
`Mentsu#all_chunchan?` is false for a set with one).

## Reproduce

`Tile.new("0m").chunchan?` is false; tanyao spec "赤五を含んでも成立する".

## Fix

Use `effective_number`, as `same_kind?`, sorting and `next_tile_notation` do.

## Compatibility

Hands with a red five gain tanyao where they have it. Found by comparing win
evaluation with the Python `mahjong` package (PyPI) on random hands.

---

赤五を含む手に断么九が付かなかった (`chunchan?` が赤五の番号 0 を見ていた)。
