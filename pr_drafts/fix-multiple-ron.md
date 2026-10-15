# ダブロン（double_ron）と三家和（triple_ron_draw）のルールを効くようにする

ブランチ: `fix/multiple-ron`

## 何が誤りか

`RuleConfig` の `double_ron`（ダブロンあり、既定 `true`）と `triple_ron_draw`（三家和で流局、既定 `true`）は
`api_reference.md` に載っていますが、どこからも参照されていません。`ActionResolver.resolve`（と
`RiichiEngine::API.resolve_pending_action`）は常に 1 つのアクションだけを返すので、同じ打牌に 2 人がロンしても
和了るのは 1 人で、3 人がロンしても三家和の流局になりません。`state_machine.md` の優先順位の表にある
「ダブロン（2人同時ロン）はルール設定で許可する場合を除き」の「許可する場合」にあたる動きがありません。
`:sanchahou` は局の終わりの種類として文書にありますが、そこへ至る道がありません。

## 再現

- `action_resolver_spec.rb` の「rule を渡したときの複数のロン」
- `round_flow_spec.rb` の「複数のロン」（ダブロン、三家和、ルールで断るもの）
- `game_flow_spec.rb` の「ダブロンに親が入っていれば連荘し、本場を積む」「親の入らないダブロンは親が流れる」
  「三家和は途中流局として連荘し、本場を積む」

## 直し

- `resolve(pending_actions, rule: nil)`（API も同じ）に任意の `rule:` を足しました。渡したときにロンが 2 人以上なら:
  - 3 人で `triple_ron_draw` が真 → `{ type: :sanchahou, seats: [...] }`
  - それ以外で `double_ron` が真 → `{ type: :ron_agari, seat: 先頭, seats: [...] }`
  - どちらでもなければ 1 人（今までと同じ）
- `apply_round_action` は `seats:` 付きの `:ron_agari` を受けます。`round_end_info[:winners]` に全員を
  放銃者の下家から順に入れ、先頭を `winner_seat` にし、イベントは和了ごとに 1 つ出します。検証は、
  全員がロンできること、人数がルールに合うこと（2 人は `double_ron`、3 人は `triple_ron_draw` が偽で
  `double_ron` のとき）を見ます。
- `:sanchahou` は途中流局として局を終えます（`round_end_info[:result_type]` が `:sanchahou`、ロンした席は
  `ron_seats`）。`GameFlow` は九種九牌と同じく親の連荘・本場 1 つ増し。
- 文書（`api_reference.md`・`concepts.md`・`state_machine.md`・`usage_examples.md`）に、引数、返り値の表、
  ダブロンの点数の求め方を書きました。

## ルール

- 天鳳と同じ組み合わせ（ダブロンあり、3 人は流局）が既定値どおりに効きます。
- ダブロンの点数: 和了った席ごとに `evaluate_win` で求めます。積み棒と供託は `winners` の先頭
  （頭はねなら和了る席。放銃者の下家から見て最初の和了者）だけが受け取るので、2 人目以降は
  `WinEvaluationSnapshot` の `honba: 0, kyoutaku: 0` で評価します（文書にこの形を書きました）。
  積み棒を和了者の全員に付けるルールもあるので、要るなら別の設定にできます。
- 親が `winners` に入っていれば連荘（今の `GameFlow.renchan?` が `winners.any?` を見ているので、そのまま）。
- 三家和は流局で点数の移動なし。供託は次局へ残り、本場が 1 つ増えます。

## 互換性

- `rule:` を渡さない呼び出しは今までと同じ 1 つのアクションを返します。`seats:` を付けない `:ron_agari` も
  今までどおりです。
- `rule:` を渡すと、既定値（`double_ron: true`）のままではダブロンになります。既定値が `true` のまま効いて
  いなかったので、効くようにすると遊び方が変わります。既定値をこのままにするか、相談したいところです。

## そのほか

- `fix/ron-turn-order`（`from_seat:`）と同じ `resolve` を触ります。両方入れるときは引数を両方持たせ
  （`from_seat:, rule:`）、`seats` を打牌者の下家から順に並べます。
- リーチ宣言牌へのロンでリーチ棒を戻すかどうかは、このブランチでは扱っていません。
