# 国士無双の暗槓の搶槓をルールのキーにする（kokushi_ankan_chankan）

ブランチ: `feat/kokushi-ankan-chankan`

## 何が足りないか

搶槓は加槓にだけあり、暗槓にはロンが出ません。暗槓した牌で国士無双が和了れるときだけ搶槓を認めるルールが
広く使われているので、選べるようにしました。

## 再現

`spec/mahjong/flow/rounds/kokushi_ankan_chankan_spec.rb`（新規）:

- 既定では暗槓にロンは無い（暗槓の新ドラはすぐめくる）
- `kokushi_ankan_chankan` なら、1z 待ちの国士無双の席にだけロンが出る（1z 単騎のふつうの手には出ない）。ロンすると暗槓した席が放銃者で、役は国士無双
- 見逃せば暗槓を終え（新ドラは暗槓としてすぐ）、見逃した席は同巡フリテン

## 直し

- `RuleConfig` に `"kokushi_ankan_chankan" => false`（今の動き）。
- `process_ankan` は、ルールが真で、暗槓の牌で国士無双が和了れる（フリテンでない）席があれば、加槓の搶槓と同じく
  `chankan_tile` と `naki_wait` でロンを待ちます。全員が見送れば `finalize_kakan` が暗槓として槓を終えます。
- ロンの扱い（`last_dahai` の席が放銃者、`round_end_info[:chankan]`）と見逃しのフリテンは加槓の搶槓と同じです。

## ルール

暗槓の搶槓なし（今の動き）が既定です。ありでも国士無双だけです。

## 互換性

既定値では今までと同じです。

---

暗槓した牌で国士無双を和了れる席に搶槓のロンを出すルールのキー kokushi_ankan_chankan を足した。
