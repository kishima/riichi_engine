# Keep red fives through discards, calls and kans

Branch: `fix/red-five`

## What is wrong

- `Hand#remove` takes the first tile of the same kind. With `0m` and `5m` in
  hand, removing `"5m"` may take the red five. A discard of 5m then leaves a 5m
  in the hand while the river shows 5m — the red five is gone from the round.
  A discard of `"5m"` from a hand that holds only `0m` puts `5m` in the river.
- Chi and pon remove the named tiles with the same rule but record the *names*
  in the meld, so the meld and the hand can disagree (a chi with `4m 0m` may
  remove the 5m, record 0m, and leave the 0m in the hand: two red fives).
- `process_ankan` / `process_daiminkan` record `Array.new(4, tile)` /
  `Array.new(3, tile)`: a red five in the kan disappears.
- `process_kakan` adds the tile named (offered as the pon's first tile, e.g.
  `"5m"`) even when the hand holds the red one.

## Reproduce

Specs in `round_flow_spec.rb` (context "赤五") and `hand_spec.rb`: discard, pon,
chi, ankan, daiminkan and kakan with a red five in the hand.

## Fix

- `Hand#remove` prefers the exact tile (red or not) and falls back to the same
  kind (callers that pass `"5m"` for a hand with only `0m` keep working).
- `RoundFlow` picks the tiles it moves from the hand (exact tile first) and
  records those in the river and in the meld; kans record the tiles taken from
  the hand.

Events keep their shape (tile names as strings).

## Compatibility

Rivers and melds now show the tile that actually moved. No API change.

---

赤五と五を持って五を切ると赤五が抜ける、チー・ポンで違う牌が動く、槓で赤五が消える、加槓で赤五が五に化ける、を直した。手から実際に動いた牌を河と副露に記録する。
