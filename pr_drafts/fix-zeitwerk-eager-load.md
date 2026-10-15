# Make the Zeitwerk loader eager-loadable

Branch: `fix/zeitwerk-eager-load`

## What is wrong

`RiichiEngine.loader.eager_load` raises `NameError`
(`uninitialized constant RiichiEngine::Api`): `riichi_engine/api.rb` defines
`API` and `riichi_engine/version.rb` defines `VERSION`, where Zeitwerk expects
`Api` and `Version`. A Rails application with `config.eager_load` (the
production default) calls `Zeitwerk::Loader.eager_load_all` at boot, which
includes this loader.

## Reproduce

`ruby -Ilib -e 'require "riichi_engine"; RiichiEngine.loader.eager_load'`;
spec `spec/riichi_engine/loader_spec.rb`.

## Fix

The loader inflects `"api"` as `API` and ignores `version.rb`, which
`riichi_engine.rb` now requires directly (as the gemspec does).

## Compatibility

None beyond the fix; `RiichiEngine::VERSION` is now defined as soon as the gem
is required (in 0.1.0 it was not, outside the gemspec).

---

`RiichiEngine.loader.eager_load` が失敗していた (`API`・`VERSION` の名前が Zeitwerk の想定と違う)。Rails の本番の eager load で起動できない。inflector と ignore で直した。
