# RiichiEngine Versioning Policy

`riichi_engine` は semver を前提に version を運用する。

## Version Format

`MAJOR.MINOR.PATCH`

例:

- `0.1.0`
- `0.2.0`
- `0.2.1`

## Bump Rules

### PATCH

後方互換を壊さない修正。

- bug fix
- ドキュメント修正
- internal 実装整理
- `RiichiEngine::API` の既存契約を変えない最適化

### MINOR

後方互換を保った機能追加。

- `RiichiEngine::API` の新メソッド追加
- 既存 snapshot を壊さない追加フィールド
- 新しい公開ドキュメントやサンプル追加

### MAJOR

破壊的変更。

- `RiichiEngine::API` の削除
- `RiichiEngine::API` の必須引数変更
- `Mahjong::Snapshots::*` の必須フィールド変更
- `RuleConfig` の既存キー意味変更

## Pre-1.0 Rule

`0.x` の間も、公開面として定義したものは semver ルールで扱う。

つまり `0.x` でも以下は破壊的変更とみなす。

- `RiichiEngine::API`
- `Mahjong::Snapshots::*`
- `Mahjong::Config::RuleConfig`

## Release Checklist

- `riichi_engine.gemspec` の version を更新
- `CHANGELOG.md` を更新
- `docs/api_reference.md` を API 変更に追従させる
- `docs/usage_examples.md` を必要に応じて更新する
- `docs/public_api_policy.md` を必要に応じて更新する
- gem 単体で `bundle exec rspec` を通す
- host app 側でも `bundle exec rspec` を通す
