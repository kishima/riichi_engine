# Break ties between calls by turn order from the discarder

Branch: `fix/ron-turn-order`

## What is wrong

When two seats can ron the same discard, `ActionResolver.resolve` (and
`RiichiEngine::API.resolve_pending_action`) breaks the tie by seat number, so
the winner depends on where the seats sit rather than on who discarded: seat 2
discards, seats 0 and 3 can ron, seat 0 wins although seat 3 is next in turn.
The validator uses the same order, so `apply_round_action` rejects the ron of
the seat that should win. (Equal priorities other than ron do not occur: two
seats cannot both pon or kan one tile.)

## Reproduce

Specs in `action_resolver_spec.rb` (`from_seat:`) and `round_flow_spec.rb`
"2 人がロンできるときは打牌者の下家に近い方が和了る（頭はね）".

## Fix

`resolve(pending_actions, from_seat: nil)` (and the API method) takes an
optional `from_seat:`. With it, equal priorities are ordered from the seat
after `from_seat`; without it the order is the seat number, as before (the
existing spec "同順位なら seat の若い順を優先する" still holds). The validator passes
the seat of the last discard (or kakan). Docs (`api_reference.md`,
`state_machine.md`, `usage_examples.md`) show the argument.

## Rule

Atamahane (head bump): of several rons on one discard, the seat closest in turn
order after the discarder wins. This is the M-League rule, and Tenhou's when
double ron is off. Double ron itself is not implemented (the rule key
`double_ron`, default `true`, has no effect today); this change does not add
it. A follow-up could make `double_ron` real — that changes play (both seats
win, and `triple_ron_draw` decides three), so it should be its own PR, and the
default may need discussion since the key already defaults to `true`.

## Compatibility

`resolve_pending_action` gains an optional keyword; calls without it behave as
before. Inside the engine, the validator now follows turn order, so a host that
applied the lower-seat ron (as the old resolver chose) gets
"higher priority action exists" when another seat is ahead in turn order.

---

同じ優先度の宣言 (2 人のロン) を席番号順で決めていた。打牌者の下家から順 (頭はね) で決める。`resolve_pending_action` には任意の `from_seat:` を足しただけで、省略時は今までどおり。ダブロンは入れていない (`double_ron` は今も効かない)。
