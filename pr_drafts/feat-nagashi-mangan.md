# 流し満貫を足す（ルールのキー nagashi_mangan）

ブランチ: `feat/nagashi-mangan`

## 何が足りないか

荒牌流局で、河の牌がすべて么九牌で、どれもほかの席に鳴かれていない席に満貫を払う「流し満貫」がありません。
採るかどうかがルールによって違うので、既定は今までどおり（なし）のキーにしました。

## 再現（新しい spec）

`spec/mahjong/flow/rounds/nagashi_mangan_spec.rb`:

- 荒牌流局で、条件に合う席が `round_end_info[:nagashi_seats]` に入ること（么九牌でない牌がある席、鳴かれた牌が
  ある席は入らない）
- 既定のルールでは `nagashi_seats` を出さないこと
- `RiichiEngine::API.calculate_nagashi_mangan_payments` の額（子・親・2 人・なし）

## 直し

- `RuleConfig` に `"nagashi_mangan" => false`。
- 荒牌流局の `round_end_info` に、ルールが真のときだけ `nagashi_seats:` を足します。
- `RiichiEngine::API.calculate_nagashi_mangan_payments(nagashi_seats, oya_seat:)` を足しました（`calculate_tenpai_payments`
  と同じ形の Hash を返します）。
- `RoundFlow.advance_turn` は任意の第 2 引数で rule を受けます（牌山が空なら局を終えるため）。
- `api_reference.md` に書きました。

## ルール

- 成立した席はそれぞれ満貫の自摸和了と同じ額を受け取ります（親なら 4000 点オール、子なら親から 4000 点・
  子から 2000 点）。本場は付きません。
- 流し満貫があればノーテン罰符の代わりにこの支払いを使います（host が `nagashi_seats` を見て選ぶ）。
- 局は流局のままで、供託は次局へ残り、親の連荘は親のテンパイで決まります。

一般に打たれている形にしました。本場を付ける、ノーテン罰符も払うといった別の扱いのルールもあるので、
要るなら別のキーにできます。

## 互換性

既定値では `round_end_info` も支払いも今までと同じです。API にメソッドが 1 つ増えます。

---

流し満貫を、ルールのキー nagashi_mangan（既定は無効）で有効にできるようにした。荒牌流局の round_end_info に成立した席を入れ、支払いは新しい API で求める。
