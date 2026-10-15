# Changelog

## 0.1.1.fmrb5（Fork の fmrb ブランチ、未公開）

### 修正

- **役の無い待ちの見逃し** — ロンの候補が出ない席（その牌では役が無い、すでにフリテン）が待ちの牌を見逃しても同巡内フリテンにならず、同じ巡のうちに役のある別の待ちでロンできた。打牌が待ちの牌なら、候補が出なかった席も同巡内フリテン（リーチ中ならリーチ後の見逃しのフリテン）にする（`fix/dojun-furiten-no-yaku`）

### 試験

- **カラテン** — ポンした牌の 4 枚目の単騎（手の内は 1 枚）は聴牌、手の内に 4 枚ある牌の単騎は聴牌でない、を spec にした。判定は変えていない（`test/karaten-tenpai`）
- 481 examples。Python `mahjong` との突き合わせは違い 0（代表 61 + 乱数 2000、seed 1。`DOUBLE_YAKUMAN=1` の seed 7 も 0）。

## 0.1.1.fmrb4（Fork の fmrb ブランチ、未公開）

### 修正

- **槓裏** — 槓の後のリーチ和了で槓裏が数えられていなかった（`RoundState#uradora_hyouji` が配牌のときのまま）（`fix/kan-uradora`）

### 機能（ルールのキー。既定はどれも 0.1.0 の動き）

- **喰い替えの禁止** — `kuikae`（既定 `true`＝あり）（`feat/kuikae`）
- **リーチ後の暗槓** — `riichi_ankan`（既定 `false`）。自摸った牌で、待ちが変わらないときだけ（`feat/riichi-ankan`）
- **国士無双の暗槓の搶槓** — `kokushi_ankan_chankan`（既定 `false`）（`feat/kokushi-ankan-chankan`）
- **包のロンの積み棒** — `pao_honba`（既定 `"discarder"`、`"liable"` で責任者）（`feat/pao-honba`）
- **天和の和了牌** — `tenhou_best_tile`（既定 `false`）。最も高い点になる牌を和了牌とする（`feat/tenhou-best-tile`）
- **南入・サドンデス** — `nan_iri`・`sudden_death`（既定 `false`）。延長戦のあるルールではアガリ止め・テンパイ止めに基準点が要る。延長戦では親を含む複数人のロンの連荘を、サドンデスと延長戦の 4 局目のアガリ止めより先にする（`feat/sudden-death`）

### 試験

- 475 examples。Python `mahjong` との突き合わせは違い 0。

## 0.1.1.fmrb3（Fork の fmrb ブランチ、未公開）

### 修正

- **CPU の向聴数** — 副露を数えておらず、鳴いた後の打牌と鳴きの判断を誤っていた。`melds:` で副露を面子として数える。通常形は色ごとに数えて覚えておき、受け入れの計算が約 20 倍速くなった（`fix/shanten-melds`）
- **第一巡** — 親の第一打牌で全員の第一巡が終わり、子の九種九牌・ダブル立直・地和が起きなかった（`fix/first-turn-flags`）
- **CPU のリーチ** — 14 枚の手のままテンパイを見ていたため、CPU が一度もリーチしなかった。切る牌は待ちの残り枚数で選ぶ（`fix/cpu-riichi`）
- **槓と牌山** — 槓のたびに牌山が 1 枚短くならず、海底と荒牌流局が遅れていた。海底牌の後は槓を出さない（`fix/kan-live-wall`）
- **知らない game_type** — ゲームが終わらず局が続いた。`RuleConfig.new` で `EngineError`（`fix/unknown-game-type`）
- **トビの文書** — api_reference.md の「0 点以下」をコードどおりの「0 点未満」に（`fix/tobi-doc`）

### 機能（ルールのキー。既定はどれも 0.1.0 の動き）

- **途中流局** — `suufon_renda`・`suukaikan`・`suucha_riichi`（既定 `false`）（`feat/abortive-draws`）
- **流し満貫** — `nagashi_mangan`（既定 `false`）。荒牌流局の `round_end_info[:nagashi_seats]` と `API.calculate_nagashi_mangan_payments`（`feat/nagashi-mangan`）
- **包** — `pao`（既定 `[]`、`"daisangen"`・`"daisuushii"`・`"suukantsu"`）。`ScoreResult#score_changes` が責任払いを割り振る（`feat/pao`）
- **明槓の新ドラ** — `minkan_dora_after_discard`（既定 `false`）。真なら明槓の新ドラは打牌のときにめくる（`feat/kan-dora-after-discard`）
- **ダブル役満** — 既存の `double_yakuman`（既定 `false`）が効くようになった。四暗刻単騎・国士無双十三面・純正九蓮宝燈・大四喜を役満 2 つ分（`feat/double-yakuman`）
- **アガリ止め・テンパイ止め** — `agari_yame`（既定 `true`）・`tenpai_yame`（既定 `false`）（`feat/agari-yame`）

### 試験

- 440 examples。`spec/compat/` の突き合わせは `DOUBLE_YAKUMAN=1` で両方のダブル役満を有効にして比べられる（違い 0）。

## 0.1.1.fmrb2（Fork の fmrb ブランチ、未公開）

### 修正

- **ダブロン・三家和** — ルールの `double_ron`・`triple_ron_draw` が効いていなかった。`resolve_pending_action` に任意の `rule:` を渡すと、2 人のロンは両方の和了（`seats:` 付きの `:ron_agari`）、3 人のロンは三家和の流局（`:sanchahou`）になる（`fix/multiple-ron`）

### 機能

- **複合役満** — ルールの `multiple_yakuman`（既定 `false`）。真なら役満が重なった手を役満の数だけ倍で数える（`feat/multiple-yakuman`）

### 試験

- `spec/compat/` の突き合わせは `multiple_yakuman` を真にして行う（Python の `mahjong` は役満を重ねる）。決まりの違いは 0 になった。

## 0.1.1.fmrb1（Fork の fmrb ブランチ、未公開）

0.1.0 に、上流へ個別に出せる形の修正（`fix/*` ブランチ、1 ブランチ 1 件）をまとめたもの。

### 修正

- **ドラ** — `evaluate_win` がドラ表示牌そのものをドラとして数えていた（裏ドラも同じ）（`fix/dora-indicators`）
- **河底撈魚** — 最後の打牌へのロンに河底撈魚が付かず、河底撈魚だけの手にロンが出なかった（`fix/houtei`）
- **リーチ中の打牌** — リーチした席に `available_round_actions` が打牌を出さず、手番が進まなかった。自摸切りだけを出し、ほかの打牌は弾く（`fix/riichi-discard`）
- **一発** — リーチした本人の次の打牌で一発が消えなかった（`fix/ippatsu`）
- **赤五** — 打牌・チー・ポン・槓で赤五が別の五とすり替わる、または局から消えた（`fix/red-five`）
- **鳴きの選択** — ロン（や大明槓）もできる席がポンを選べなかった（`fix/call-own-options`）
- **頭はね** — 同じ優先度の宣言を席番号順で決めていた。打牌者の下家から順に決める（`resolve_pending_action` に任意の `from_seat:`）（`fix/ron-turn-order`）
- **牌山の seed** — 英数字以外を含む seed がその文字の手前までしか使われず、`"round-001"` と `"round-002"` が同じ山になった（`fix/wall-seed`）
- **CPU の打牌** — normal（と hard の多くの場面）が受け入れのいちばん少ない形を残していた（`fix/cpu-discard-ukeire`）
- **東風戦** — 文書の `game_type` `"tonpuu"` でゲームが終わらなかった（`fix/tonpuu-game-type`）
- **Zeitwerk** — `RiichiEngine.loader.eager_load` が失敗した（`fix/zeitwerk-eager-load`）
- **断么九** — 赤五を含む手に断么九が付かなかった（`fix/tanyao-red-five`）
- **双碰のロンの符** — ロンで完成した刻子を暗刻の符で数えていた（`fix/shanpon-ron-fu`）
- **待ちの取り方** — 和了牌が複数の待ちに取れるとき（単騎と両面など）最初の 1 つしか見ず、平和や高い符を逃した（`fix/machi-interpretation`）
- **二盃口** — 同じ順子 4 つが一盃口になっていた（`fix/ryanpeiko-four-sequences`）

### 試験

- `spec/compat/`: Python の `mahjong`（PyPI）と、和了の形（乱数と役ごとの代表）で役・翻・符・点数を突き合わせる。Python とそのパッケージが無ければ飛ばす。

## 0.1.0 (2026-04-05)

初回リリース

### 機能

- **局進行** — 自摸・打牌・リーチ・ポン・チー・カン（暗槓・加槓・大明槓）・九種九牌の処理
- **和了判定** — 通常和了形・七対子・国士無双に対応
- **役判定** — 一般役から役満まで全役対応（ダブル役満はルール設定で切り替え可）
- **点数計算** — 符・翻計算、基本点・各プレイヤーへの支払い点算出、本場加算
- **流局処理** — 荒牌流局・途中流局（四風連打・四家リーチ・三家和・四槓散了）、ノーテン罰符計算
- **ゲーム進行** — 連荘・親流れ・オーラス終了条件・トビ判定・西入対応
- **順位計算** — ウマ・オカを含む最終スコア算出
- **CPU AI** — Easy / Normal / Hard の3段階
- **状態の永続化** — `RoundState` の JSON シリアライズ・デシリアライズ
