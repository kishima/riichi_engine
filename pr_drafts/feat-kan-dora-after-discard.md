# 明槓の新ドラを打牌の後にめくる設定を足す（minkan_dora_after_discard）

ブランチ: `feat/kan-dora-after-discard`

## 何が足りないか

エンジンはすべての槓で、槓の直後に新ドラをめくります。多くのルールでは、直後にめくるのは暗槓だけで、
明槓（大明槓・加槓）の新ドラはその後の打牌のときにめくります。どちらにするかはルールによって違うので、
既定は今までどおり（直後）のキーにしました。

## 再現（新しい spec）

`spec/mahjong/flow/rounds/kan_dora_spec.rb`:

- 既定のルールでは大明槓の直後にめくること
- `minkan_dora_after_discard` なら、大明槓・加槓の新ドラは打牌のときにめくること
- 打牌の前に次の槓（暗槓）をすれば、残っていた新ドラと暗槓の新ドラをそのときにめくること
- 暗槓は設定にかかわらず直後にめくること
- めくっていない新ドラの数が RoundState の JSON に残ること

## 直し

- `RuleConfig` に `"minkan_dora_after_discard" => false`。
- `RoundState#pending_kan_dora`（まだめくっていない新ドラの数）を足し、`to_json`・`from_json` に入れました。
- `apply_kan_transition` は、設定が真なら明槓の新ドラを数えておき、その席の打牌のとき（その打牌へのロンを
  探す前）か次の槓のときにめくります。嶺上開花の自摸和了ではめくりません。
- `apply_kan_transition` と `finalize_kakan` は任意で rule を受けます。
- `api_reference.md` の表と `state_machine.md` に書きました。

## ルール

明槓の新ドラは打牌の後（その打牌へのロンには乗る）、次の槓が先なら槓のとき、嶺上開花には乗らない。
一般に打たれている決まりです。

## 互換性

既定値では今までと同じです。RoundState の JSON に `pending_kan_dora` が増えます（無い JSON は 0 として読みます）。

---

明槓（大明槓・加槓）の新ドラを、槓の直後ではなく打牌のときにめくる設定 minkan_dora_after_discard を足した（既定は今までどおり直後）。
