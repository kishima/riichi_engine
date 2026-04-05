# RiichiEngine Release Process

## 1. Prepare

- `CHANGELOG.md` を更新する
- 必要なら `README.md`, `docs/api_reference.md`, `docs/usage_examples.md` を更新する
- `riichi_engine.gemspec` の version を上げる

## 2. Verify

gem 単体:

```bash
bundle install --local
bundle exec rspec
```

host app 側:

```bash
cd /path/to/host_app
bundle exec rspec
```

## 3. Configure Secrets

GitHub repository secrets に以下を設定する。

- `RUBYGEMS_API_KEY`

この API key は push 権限を持つ RubyGems account で発行する。

## 4. Tag

```bash
git tag v0.1.0
git push origin v0.1.0
```

## 5. Release Workflow

`v*` tag push で GitHub Actions の `release.yml` が動く。

実行内容:

- `bundle exec rspec`
- `gem build riichi_engine.gemspec`
- `gem push riichi_engine-*.gem`

失敗しやすい点:

- `RUBYGEMS_API_KEY` 未設定
- version 未更新のまま既存 version を push しようとする
- `CHANGELOG` や API docs が release 内容に追従していない

## 6. Host App Update

host app が Git source 参照の場合は、tag か commit SHA を更新する。

```ruby
gem "riichi_engine", git: "...", tag: "v0.1.0"
```
