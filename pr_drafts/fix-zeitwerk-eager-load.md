# Zeitwerk の loader を eager load できるようにする

ブランチ: `fix/zeitwerk-eager-load`

## 何が誤りか

`RiichiEngine.loader.eager_load` が `NameError`（`uninitialized constant RiichiEngine::Api`）になります。
`riichi_engine/api.rb` は `API` を、`riichi_engine/version.rb` は `VERSION` を定義しますが、Zeitwerk は
`Api` と `Version` を期待します。`config.eager_load`（production の既定）の Rails アプリケーションは起動時に
`Zeitwerk::Loader.eager_load_all` を呼び、この loader も含まれます。

## 再現

`ruby -Ilib -e 'require "riichi_engine"; RiichiEngine.loader.eager_load'`、spec `spec/riichi_engine/loader_spec.rb`。

## 直し

loader の inflector で `"api"` を `API` とし、`version.rb` は ignore して `riichi_engine.rb` から直接 require します
（gemspec と同じ）。

## 互換性

修正のほかに変わるのは、gem を require した時点で `RiichiEngine::VERSION` が定義されることだけです
（0.1.0 では gemspec の外では定義されていませんでした）。

---

`RiichiEngine.loader.eager_load` が失敗していた（`API`・`VERSION` の名前が Zeitwerk の想定と違う）。Rails の本番の eager load で起動できない。inflector と ignore で直した。
