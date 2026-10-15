# アガリ止め・テンパイ止めをルールのキーにする（agari_yame・tenpai_yame）

ブランチ: `feat/agari-yame`（`fix/tonpuu-game-type` の上）

## 何が足りないか

`GameFlow` は、オーラスで首位の親が和了ると常にゲームを終え（アガリ止め）、テンパイで流局すると常に続けます。
どちらもルールによって違うので、既定値を今の動きにしたキーにしました。

## 再現

`game_flow_spec.rb` の「アガリ止め・テンパイ止め」:

- 既定: 首位の親の和了で終わり（理由 `:all_last_oya_agari`）、テンパイ流局では続く
- `agari_yame` が偽なら和了っても続く（連荘、本場 1 つ増し）
- `tenpai_yame` なら首位の親のテンパイ流局で終わる（理由 `:all_last_oya_tenpai`）
- `tenpai_yame` でも親が首位でなければ続く

## 直し

- `RuleConfig` に `"agari_yame" => true`・`"tenpai_yame" => false`。
- `GameFlow.all_last_oya_stop` が、オーラスで親が首位（今までと同じ判定: 最高点と同点以上で正の点）のとき、
  ルールに従って終わる理由を返します。`all_last_oya_agari?` は残してあります。
- `api_reference.md` の表と `state_machine.md` の図に書きました。

`fix/tonpuu-game-type`（`"tonpuu"` のオーラスも同じ判定に入る）の上に作ってあります。

## ルール

アガリ止めあり・テンパイ止めなし（今の動き）が既定です。テンパイ止めありのルールも多いので選べます。

## 互換性

既定値では今までと同じです。`GameFlowResult#reason` に `:all_last_oya_tenpai` が増えます（`tenpai_yame` のときだけ）。

---

オーラスの親のアガリ止め（今は常にあり）とテンパイ止め（今は常になし）を、既定値を今の動きにしたルールのキーにした。
