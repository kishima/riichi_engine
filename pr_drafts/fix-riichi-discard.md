# Offer the drawn tile as the discard of a seat in riichi

Branch: `fix/riichi-discard`

## What is wrong

For a seat in riichi, `available_round_actions` returns no `:dahai` at all
(only `:tsumo_agari` when it can win). A host that offers the player what the
engine lists has nothing to send, and the engine's own CPU stops too:
`BaseAi#think` returns `nil` when the list is empty. Meanwhile the validator
accepts *any* discard from a seat in riichi.

## Reproduce

Seat 0 in riichi with a drawn tile: `available_round_actions(seat: 0)` is `[]`
(spec "リーチ後の available_actions…"); `BaseAi#think` returns nil.

## Fix

- `available_actions` offers one `{ type: :dahai, tile: <drawn tile> }` to a
  seat in riichi (plus `:tsumo_agari` when it can win, as before);
- the validator rejects any other discard from that seat
  ("riichi player must discard the drawn tile");
- `BaseAi` discards the drawn tile while in riichi.

## Compatibility

`available_round_actions` returns one more entry for a seat in riichi. The
spec that expected `[]` ("…自摸和了以外のボタンを返さない") now expects the single
tsumogiri; if the empty list was meant as "the host discards automatically",
that is not documented and the engine's own AI could not continue, so the
explicit entry seemed the consistent choice. A host that discarded some other
tile for a seat in riichi now gets `InvalidActionError` (riichi forbids it).
Closed kans during riichi are still not offered (unchanged).

---

リーチした席に打牌の選択肢が出ず、手番が止まっていた (エンジンの CPU も止まる)。自摸切りだけを出し、ほかの打牌は弾き、CPU も自摸切りする。
