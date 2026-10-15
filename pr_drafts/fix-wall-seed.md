# Use the whole seed string when it is not base 36

Branch: `fix/wall-seed`

## What is wrong

`Wall.build` turns the seed into a number with `String#to_i(36)`, which stops
at the first character outside `0-9a-z`. `"round-001"` (the README's quick
start) and `"round-002"` both read as `"round"`, so they build the same wall;
so do `"test-seed"` and `"test-other"`.

## Reproduce

`Wall.build(seed: "round-001").to_a == Wall.build(seed: "round-002").to_a`
(spec "英数字以外を含む seed も全体で区別する").

## Fix

A seed made only of `0-9a-z` (either case) is read as before, so its wall is
the same as in 0.1.0 (spec "英数字だけの seed は従来と同じ順序になる"). Any other
seed is hashed as a whole (SHA-256 of the string, as an integer seed for
`Random`).

## Compatibility

Seeds with other characters build a different wall than in 0.1.0 (they could
not be told apart before). Base-36 seeds are unchanged. `digest` is from the
standard library.

---

seed を `to_i(36)` で読むため `-` などの手前で切れ、README の例の `"round-001"` と `"round-002"` が同じ山になっていた。英数字だけの seed は今までどおり、ほかは文字列全体のハッシュを使う。
