# 包のロンの積み棒を責任者に払わせるキー（pao_honba）

ブランチ: `feat/pao-honba`（`feat/pao` の上）

## 何が足りないか

`feat/pao` では、包のある役満を責任者以外の席がロンしたとき、包の分を放銃者と責任者で半分ずつ払い、積み棒は
放銃者が払います。ツモでは積み棒も責任者が払うので、ロンでも積み棒を責任者が払うルールがあります（「積み棒も包」）。
それを選べるようにしました。

## 再現

`spec/mahjong/scoring/evaluators/pao_spec.rb` に 2 例:

- `pao_honba: "liable"` なら、ほかの席からのロンの積み棒（1 本場 300 点）は包の席が払う
- `pao_honba: "liable"` でも、包の無い和了の積み棒は放銃者

## 直し

- `RuleConfig` に `"pao_honba" => "discarder"`（今の動き）。値は `"discarder"` か `"liable"`。
- `ScoreCalculator.calculate` がルールの値を `ScoreResult#pao_honba` に入れ、`score_changes` の包の割り振りが
  ロンの積み棒をその席に払わせます。
- `api_reference.md` の表に書きました。

## 互換性

既定値では今までと同じです。

---

包のある役満を責任者以外がロンしたときの積み棒を、放銃者（今の動き）か責任者かで選べるキー pao_honba を足した。
