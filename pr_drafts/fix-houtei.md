# Apply houtei to a ron on the last discard

Branch: `fix/houtei`

## What is wrong

`RoundState#is_houtei?` is `is_haitei? && phase == :naki_wait`, and both
places that build the yaku context call it outside that phase:

- ron candidates are detected inside `process_dahai`, before the phase becomes
  `:naki_wait` (it is still `:dahai`);
- `evaluate_win` is called after `process_ron_agari`, when the phase is
  `:round_end`.

So houtei never applies to a win, and a hand whose only yaku is houtei is never
offered a ron on the last discard.

## Reproduce

Empty wall, seat 0 discards 3s, seat 1 holds `123m 456p 789s 99m 24s` (no yaku
but houtei): after the discard the round ends in an exhaustive draw instead of
waiting for seat 1's ron, and if the ron is applied by hand `evaluate_win` has
no houtei. Spec: `round_flow_spec.rb` "最後の打牌は河底撈魚だけでロンでき…", and a
guard that a tsumo on the last tile has haitei and not houtei.

## Fix

Both context builders decide houtei from the wall and the kind of win: a ron
(not a chankan) when the wall is empty. `RoundState#is_houtei?` is left as it
is.

The NakiDetector spec "海底ではロン以外の鳴きを検出しない" expected no option for a
seat whose shanpon wait gets houtei on that discard; it now expects that seat's
ron (still no pon), which is what the spec name says.

## Rule

Houtei: a ron on the discard after the last draw (Tenhou, M-League). A chankan
on the last tile is chankan, not houtei, here as in both.

## Compatibility

Wins on the last discard gain one han; some last discards that used to end in
an exhaustive draw are now won. No API change.

---

最後の打牌へのロンに河底撈魚が付かず、河底撈魚だけの手にはロンも出なかった (phase を見ていたため)。牌山が空でのロン (槍槓を除く) で判定するようにした。
