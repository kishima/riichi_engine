# Accept the documented game_type "tonpuu"

Branch: `fix/tonpuu-game-type`

## What is wrong

README and `docs/api_reference.md` name the east-only game `"tonpuu"`, but
`GameFlow` only knows `"tonpuusen"`. With the documented value,
`should_end_game?` falls through to `false` and the game never ends; the
all-last dealer win does not end it either.

## Reproduce

`RuleConfig.new("game_type" => "tonpuu")`, East 4 won by a non-dealer:
`judge_next` gives the next round (South 1) instead of the game end. Specs in
`game_flow_spec.rb`.

## Fix

Both names mean the east-only game. The docs keep `"tonpuu"` and mention
`"tonpuusen"`.

## Compatibility

`"tonpuusen"` works as before. An unknown `game_type` still never ends (not
changed here; raising for it might be worth a separate change).

---

文書の `"tonpuu"` ではゲームが終わらなかった (コードは `"tonpuusen"` しか知らない)。両方を東風戦として扱う。
