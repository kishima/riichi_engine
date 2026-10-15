# 同じ優先度の宣言は、打牌者の下家から順に決める（頭はね）

ブランチ: `fix/ron-turn-order`

## 何が誤りか

同じ打牌に 2 人がロンできるとき、`ActionResolver.resolve`（と `RiichiEngine::API.resolve_pending_action`）は
席番号の若い順で決めます。誰が打牌したかではなく席の位置で和了る人が決まります: 席 2 の打牌に席 0 と席 3 が
ロンできるとき、手番では席 3 が先なのに席 0 が和了ります。検証も同じ順なので、和了るべき席のロンを
`apply_round_action` が弾きます（ロン以外の同じ優先度は起きません。1 枚の牌を 2 人がポン・槓することはできません）。

## 再現

`action_resolver_spec.rb`（`from_seat:`）と `round_flow_spec.rb` の
「2 人がロンできるときは打牌者の下家に近い方が和了る（頭はね）」。

## 直し

`resolve(pending_actions, from_seat: nil)`（API のメソッドも）に任意の `from_seat:` を足しました。渡すと、
同じ優先度は `from_seat` の下家から順に並べます。渡さなければ今までどおり席番号の順です（既存の spec
「同順位なら seat の若い順を優先する」はそのまま通ります）。検証は最後の打牌（か加槓）の席を渡します。
文書（`api_reference.md`・`state_machine.md`・`usage_examples.md`）に引数を書きました。

## ルール

頭はね: 1 つの打牌への複数のロンは、打牌者から見て手番の近い席が和了ります。M リーグの決まりで、
ダブロンなしのときの天鳳も同じです。ダブロンそのものはこのブランチでは入れていません（ルールのキー
`double_ron`、既定 `true` は今も効いていません）。`double_ron` を効かせると遊び方が変わる（2 人とも和了り、
3 人は `triple_ron_draw` で決まる）ので別の PR にしました（`fix/multiple-ron`）。キーの既定値がすでに
`true` なので、既定値は相談が要るかもしれません。

## 互換性

`resolve_pending_action` には任意のキーワードが 1 つ増えるだけで、渡さない呼び出しは今までどおりです。
エンジンの中では検証が手番の順に従うので、席番号の若い方のロン（今までの resolver が選んだ方）を適用していた
host は、手番の先の席がいるとき "higher priority action exists" を受けます。

---

同じ優先度の宣言（2 人のロン）を席番号順で決めていた。打牌者の下家から順（頭はね）で決める。`resolve_pending_action` には任意の `from_seat:` を足しただけで、省略時は今までどおり。ダブロンは入れていない（`double_ron` は今も効かない）。
