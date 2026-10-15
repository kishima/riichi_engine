# Let a seat choose a lower call over its own other options

Branch: `fix/call-own-options`

## What is wrong

`ActionValidator.highest_priority_action?` resolves all pending actions, the
calling seat's own other options included. A seat that can both ron and pon a
discard (or daiminkan and pon) is therefore told "higher priority action
exists" when it chooses the pon — although no other seat has a higher claim.
The same seat could only pon by skipping, which is not possible either.

## Reproduce

`pending_actions = { 1 => [{ type: :ron_agari }, { type: :pon, ... }] }`, seat 1
declares pon: invalid. Specs in `action_validator_spec.rb` (ron + pon,
daiminkan + pon, and that another seat's ron still blocks the pon).

## Fix

Compare the declared action with the other seats' pending actions only (the
declaring seat's entry is replaced by the declared action).

## Compatibility

Calls that were wrongly rejected are accepted. No API change.

---

ロン (や大明槓) もできる席がポンを選ぶと「より優先の宣言がある」と弾かれていた。自分のほかの選択肢とは比べないようにした。
