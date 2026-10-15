# Tile#chunchan? で赤五を中張牌として扱う

ブランチ: `fix/tanyao-red-five`

## 何が誤りか

`Tile#chunchan?` は `number >= 2 && number <= 8` を見ていますが、赤五は `number == 0` です。赤五を含む手には
断么九が付きません（赤五を含む面子の `Mentsu#all_chunchan?` も偽になります）。

## 再現

`Tile.new("0m").chunchan?` が偽。断么九の spec「赤五を含んでも成立する」。

## 直し

`same_kind?`・並べ替え・`next_tile_notation` と同じく `effective_number` を見ます。

## 互換性

赤五を含む手に、成立していれば断么九が付きます。Python の `mahjong` パッケージと乱数の手で和了の評価を
突き合わせて見つけました。

---

赤五を含む手に断么九が付かなかった（`chunchan?` が赤五の番号 0 を見ていた）。
