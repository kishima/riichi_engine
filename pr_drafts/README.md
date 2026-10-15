# Pull request drafts

One draft per `fix/*` branch. Every branch starts from `main` (v0.1.0), has
its own failing-then-passing spec and does not depend on another; they can be
sent in any order. Where two branches touch neighbouring lines (noted below),
the second one to be merged needs a trivial rebase.

| Branch | Draft | Spec files |
|---|---|---|
| `fix/dora-indicators` | [fix-dora-indicators.md](fix-dora-indicators.md) | scoring/evaluators/win_evaluator_spec.rb (new) |
| `fix/houtei` | [fix-houtei.md](fix-houtei.md) | flow/rounds/round_flow_spec.rb, flow/detectors/naki_detector_spec.rb |
| `fix/riichi-discard` | [fix-riichi-discard.md](fix-riichi-discard.md) | round_flow_spec.rb, cpu/ai/base_ai_spec.rb |
| `fix/ippatsu` | [fix-ippatsu.md](fix-ippatsu.md) | round_flow_spec.rb |
| `fix/red-five` | [fix-red-five.md](fix-red-five.md) | round_flow_spec.rb, state/hand_spec.rb |
| `fix/call-own-options` | [fix-call-own-options.md](fix-call-own-options.md) | flow/validators/action_validator_spec.rb |
| `fix/ron-turn-order` | [fix-ron-turn-order.md](fix-ron-turn-order.md) | flow/resolvers/action_resolver_spec.rb, round_flow_spec.rb |
| `fix/wall-seed` | [fix-wall-seed.md](fix-wall-seed.md) | tiles/wall_spec.rb |
| `fix/cpu-discard-ukeire` | [fix-cpu-discard-ukeire.md](fix-cpu-discard-ukeire.md) | cpu/selectors/dahai_selector_spec.rb |
| `fix/tonpuu-game-type` | [fix-tonpuu-game-type.md](fix-tonpuu-game-type.md) | flow/games/game_flow_spec.rb |
| `fix/zeitwerk-eager-load` | [fix-zeitwerk-eager-load.md](fix-zeitwerk-eager-load.md) | riichi_engine/loader_spec.rb (new) |
| `fix/tanyao-red-five` | [fix-tanyao-red-five.md](fix-tanyao-red-five.md) | tiles/tile_spec.rb, scoring/yaku/tanyao_spec.rb |
| `fix/shanpon-ron-fu` | [fix-shanpon-ron-fu.md](fix-shanpon-ron-fu.md) | scoring/calculators/fu_calculator_spec.rb |
| `fix/machi-interpretation` | [fix-machi-interpretation.md](fix-machi-interpretation.md) | scoring/judges/machi_judge_spec.rb, win_evaluator_spec.rb (new) |
| `fix/ryanpeiko-four-sequences` | [fix-ryanpeiko-four-sequences.md](fix-ryanpeiko-four-sequences.md) | scoring/yaku/pattern_yaku_spec.rb |
| `fix/multiple-ron` | [fix-multiple-ron.md](fix-multiple-ron.md) (Japanese) | flow/resolvers/action_resolver_spec.rb, round_flow_spec.rb, flow/games/game_flow_spec.rb |
| `feat/multiple-yakuman` | [feat-multiple-yakuman.md](feat-multiple-yakuman.md) (Japanese) | scoring/evaluators/multiple_yakuman_spec.rb (new), scoring/calculators/score_calculator_spec.rb |

The upstream author writes in Japanese, so the pull requests go in Japanese.
The two newest drafts are; the older ones above are still in English and are
to be rewritten before they are sent.

Neighbouring changes (a rebase after the first is merged):

- `fix/dora-indicators`, `fix/houtei` and `fix/machi-interpretation` all edit
  the context built in `WinEvaluator.evaluate`; the first and the last both
  add `win_evaluator_spec.rb`.
- `fix/houtei` and `fix/red-five` add private helpers at the same place in
  `round_flow.rb`.
- `fix/call-own-options` and `fix/ron-turn-order` edit the same two lines of
  `ActionValidator.highest_priority_action?`.
- `fix/ron-turn-order` and `fix/multiple-ron` both add a keyword to
  `ActionResolver.resolve` and `resolve_pending_action`; together they take
  both (`from_seat:, rule:`) and the ron seats are ordered from the discarder.

Rule choices (Tenhou / M-League; the defaults keep 0.1.0's behaviour where a
rule is a matter of choice):

- Houtei on the discard after the last draw, not on a chankan.
- Ippatsu until the player's own next discard; any call ends it.
- Atamahane between rons, by turn order from the discarder, when the resolver
  is called without `rule:`. With `rule:` (`fix/multiple-ron`), `double_ron`
  and `triple_ron_draw` take effect: double ron, and three rons as sanchahou
  (Tenhou's combination, the keys' defaults). Honba and riichi sticks go to
  the first winner from the discarder.
- Several yakuman in one hand: one yakuman by default (0.1.0), added up with
  the new `multiple_yakuman` (`feat/multiple-yakuman`). `double_yakuman` is
  still unused.

The gemspec already declares `spec.license = "MIT"` (and the published 0.1.0
has it); nothing to change there.

Not addressed (seen, left for later): a kan does not shorten the live wall
(the replacement tile comes from the dead wall, which is never refilled);
tobi ends the game below 0 points (as `state_machine.md` says) while
`api_reference.md` says "0 or below" — one of the two documents needs a fix,
depending on the intended rule; whether `easy` keeps the least acceptance on
purpose.
