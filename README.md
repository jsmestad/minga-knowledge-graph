# Minga Knowledge Graph

See how familiar you are with each file in [Minga](https://github.com/jsmestad/minga). The extension tracks opens and edits over time and tints the file tree by familiarity.

## Install

Use a Minga build that includes the extension notice API from [Minga #3764](https://github.com/jsmestad/minga/issues/3764). Add this line to `~/.config/minga/config.exs` (or `$XDG_CONFIG_HOME/minga/config.exs`), then restart Minga and approve the Git install prompt:

```elixir
extension :minga_knowledge_graph, git: "https://github.com/jsmestad/minga-knowledge-graph"
```

If you used the bundled extension, the Git install keeps the same extension ID and reuses `extensions/minga_knowledge_graph/data/graph.json` under your Minga data directory. No data migration is needed.

## Use

- `SPC k k` shows familiarity for the current file.
- `SPC k r` refreshes the file-tree heat map.
- `SPC k b` opens a briefing for the current file. A briefing sends an excerpt of the on-disk file to Minga's configured AI provider only when you request it.

## Develop

Use the Elixir and Erlang/OTP versions in the [CI workflow](.github/workflows/ci.yml):

```sh
export MIX_ENV=test
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix credo
mix test --warnings-as-errors
```

[MIT license](LICENSE)
