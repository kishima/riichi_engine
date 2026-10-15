# Count a triplet completed by ron as an open triplet in the fu

Branch: `fix/shanpon-ron-fu`

## What is wrong

On a shanpon wait won by ron, the triplet the winning tile completes counts as
an open triplet. `SanAnkou` and `Suuankou` already handle this
(`agari_type == :ron && machi_type == :shanpon`), but `FuCalculator` counts the
triplet with the concealed fu (4, or 8 for terminals and honors).

## Reproduce

`555z 222m 678p 345s 99p`, waiting on 2m/9p, ron on 2m, closed: 20 + 10
(closed ron) + 8 (white, concealed) + 2 (2m, open) = 40 fu; the engine gives 50.
Spec in `fu_calculator_spec.rb` (and that a tsumo keeps the concealed fu).

## Fix

`FuCalculator.mentsu_fu` halves the fu of the concealed triplet that holds the
winning tile when the win is a ron on a shanpon wait.

## Compatibility

Some ron wins drop by 10 fu. Found by the comparison with the Python
`mahjong` package.

---

双碰待ちのロンで完成した刻子を暗刻の符で数えていた (三暗刻・四暗刻の判定は明刻扱いで正しかった)。符も明刻で数える。
