# normal の CPU は、受け入れのいちばん多い打牌を選ぶ

ブランチ: `fix/cpu-discard-ukeire`

## 何が誤りか

`TileEvaluator.evaluate_all_discards` は打牌ごとに、その後の手の受け入れ枚数を返します。
`DahaiSelector.select_normal` は向聴数がいちばん小さい候補をその受け入れで*昇順*に並べて先頭を取るので、
CPU は受け入れのいちばん少ない形を残します（両面より嵌張）。`select_hard` はテンパイ近くでは
`select_normal` に任せ、`select_defensive` はすでに `-ukeire` で並べています。

## 再現

`123m 456p 789s 22m 34s 6s` と何か 1 枚: 6s（か 9s）を切れば 2s-5s 待ち（8 枚）、3s を切れば 5s の嵌張（4 枚）が残ります。
レベル 2 と 3 は 3s を切ります。`dahai_selector_spec.rb` の spec。normal の CPU 4 人の半荘 40 回
（リーチの打牌は `fix/riichi-discard` の形で渡す）で、452 局のうち 341 局（75 %）が荒牌流局でした。
この修正（とほかの修正）を入れると 488 局のうち 85 局（17 %）です。

## 直し

受け入れの降順に並べます。危険度と牌の名前で同点を決めるのは今までどおりです。easy はそのままにしました
（么九牌を先に切る作りで、弱くしてあるのかもしれません）。

## 互換性

normal と hard の CPU の打ち方が変わります（よくなります）。API の変更はありません。

---

CPU（normal、と hard の多く）が受け入れのいちばん少ない形を残していた（並べ替えが昇順）。受け入れの多い方を残すようにした。easy は変えていない。
