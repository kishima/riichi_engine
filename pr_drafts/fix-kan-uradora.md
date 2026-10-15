# 槓裏を和了の評価に入れる（fix/kan-uradora）

ブランチ: `fix/kan-uradora`（`fix/dora-indicators` の上）

## 何が起きるか

槓をすると王牌から新ドラの表示牌と、その下の槓裏の表示牌が 1 枚ずつ増えます（`Wanpai#reveal_new_dora!`）。
ところが `RoundFlow` が局の状態に写すのは `dora_hyouji` だけで、`RoundState#uradora_hyouji` は配牌のときの 1 枚のままです。
`WinEvaluator` は裏ドラを `RoundState#uradora_hyouji` から数えるので、槓の後にリーチで和了っても槓裏が乗りません
（ロン・ツモの候補の判定は王牌を直接読むので、槓裏を数えています）。

## 再現

`spec/mahjong/flow/rounds/kan_uradora_spec.rb`（新規）:

- 暗槓の後、`RoundState#uradora_hyouji` に槓裏の表示牌が入る
- 立直の嶺上ツモで、槓裏（表示牌 1z → 2z を暗槓）が裏ドラ 4 として数えられる
- JSON に保存して読み戻しても槓裏が残る

## 直し

槓で新ドラをめくるとき、`state.uradora_hyouji` も王牌から写します（`dora_hyouji` と同じ扱い）。

ドラを表示牌の次の牌で数える `fix/dora-indicators` の上に作ってあります（そちらが無いと、表示牌そのものを数えるため
試験の点数が変わります）。

## 互換性

槓のある局で、リーチの和了に槓裏が乗るようになります。それ以外は変わりません。

---

槓の後のリーチ和了で槓裏が数えられていなかったのを直した。
