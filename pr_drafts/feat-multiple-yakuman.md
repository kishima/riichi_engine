# 複合役満の設定（multiple_yakuman）を足す

ブランチ: `feat/multiple-yakuman`

## 何が足りないか

1 つの手で役満が 2 つ以上成立したとき（大三元と字一色など）、役の一覧には両方が入りますが、点数は常に役満
1 つ分です。役満を重ねて数えるか（天鳳は重ねる）はルールによって違うので、選べるとよいと考えました。
既存の `double_yakuman`（ダブル役満あり、既定 `false`）は点数の計算で使われておらず、名前からは
四暗刻単騎などの「2 倍の役満」を指すようにも読めるので、別のキーにしました。

## 再現

- `spec/mahjong/scoring/evaluators/multiple_yakuman_spec.rb`（新規）: 大三元・字一色の手のロンが、既定では
  32000 点、`multiple_yakuman` で 64000 点（「2倍役満」）。
- `score_calculator_spec.rb`: `yakuman_count: 2` の親ツモが 32000 点オール、役満でない手には効かないこと。

## 直し

- `RuleConfig` に `"multiple_yakuman" => false` を足しました（`api_reference.md` の表にも）。
- `ScoreCalculator.calculate` に任意の `yakuman_count:`（既定 1）を足しました。役満のときだけ基本点を
  その数だけ倍にし、段階の表示は「2倍役満」「3倍役満」とします。
- `WinEvaluator` は、`multiple_yakuman` が真なら成立した役満の数を渡します。

## ルール

- 既定値 `false` は 0.1.0 の点数のまま（役満は重なっても 1 つ）。
- 数え役満には効きません。
- 役満そのものを 2 倍にする（四暗刻単騎・国士無双十三面・純正九蓮宝燈・大四喜）ルールは、このブランチでは
  扱っていません。`double_yakuman` をその意味で実装するなら別の変更です。

## 互換性

既定値では点数が変わりません。`ScoreCalculator.calculate` の引数は任意のキーワードを 1 つ足しただけです。

## 確かめたこと

Python の `mahjong`（PyPI、役満を重ねて数える）と和了の形 30,000 で突き合わせ、`multiple_yakuman` を真に
すると役満の重なった手も一致しました（偽のままでは、その手だけが決まりの違いとして残ります）。
