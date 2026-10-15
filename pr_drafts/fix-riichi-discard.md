# リーチ中の席に、自摸切りを打牌の選択肢として出す

ブランチ: `fix/riichi-discard`

## 何が誤りか

リーチ中の席に対して `available_round_actions` は `:dahai` を 1 つも返しません（和了れるときの `:tsumo_agari` だけ）。
エンジンが返す選択肢をそのまま見せる host では送るものが無く、エンジン自身の CPU も止まります
（一覧が空なら `BaseAi#think` は `nil` を返します）。一方で検証（ActionValidator）は、リーチ中の席の
どんな打牌も受け付けます。

## 再現

席 0 がリーチ中で自摸した後: `available_round_actions(seat: 0)` が `[]`（spec「リーチ後の available_actions…」）、
`BaseAi#think` が nil を返します。

## 直し

- `available_actions` は、リーチ中の席に `{ type: :dahai, tile: 自摸した牌 }` を 1 つ出します（和了れるときの
  `:tsumo_agari` は今までどおり）。
- 検証は、その席のそれ以外の打牌を弾きます（"riichi player must discard the drawn tile"）。
- `BaseAi` はリーチ中は自摸切りします。

## 互換性

リーチ中の席に対する `available_round_actions` の返り値が 1 つ増えます。`[]` を期待していた spec
（「…自摸和了以外のボタンを返さない」）は、自摸切り 1 つを期待するように直しました。空の一覧が
「host が自動で切る」という意味だったとしても文書には無く、エンジンの CPU が続けられないので、
明示の選択肢を出すのが一貫すると考えました。リーチ中の席にほかの牌を切らせていた host は
`InvalidActionError` を受けます（リーチではできない打牌です）。リーチ中の暗槓は今までどおり出しません。

---

リーチした席に打牌の選択肢が出ず、手番が止まっていた（エンジンの CPU も止まる）。自摸切りだけを出し、ほかの打牌は弾き、CPU も自摸切りする。
