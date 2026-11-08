# Contributing to helix.hume

- **Bug reports are always welcome.** Include your HUME version (`hume --version`), the keys
  you pressed, what Helix does with them and what the plugin did instead.
- **Small, focused fixes** can go straight to a pull request.

By contributing you agree that your work is licensed under the [MIT License](LICENSE).

## Getting set up

`(load-plugin! "cvlmtg/helix.hume")` resolves one path only, so a working copy has to be
reachable there:

| Platform | `<data>/plugins/cvlmtg/helix.hume/` resolves under |
|---|---|
| macOS, Linux | `$XDG_DATA_HOME/hume/`, default `~/.local/share/hume/` |
| Windows | `%LOCALAPPDATA%\hume\`, falling back to `%APPDATA%\hume\` if `LOCALAPPDATA` is unset |

Either clone your fork straight into that path and work there, or symlink it there from a
checkout elsewhere; path resolution follows symlinks. A symlinked checkout counts as
installed, so `:plum-update-plugins` will run `git pull` inside your working tree.

Iterating: edit `plugin.scm`, then `:reload-config` inside HUME. It resets every plugin and
re-runs `init.scm`, so the edited body is evaluated again with no restart.

## Code standards

- Editor command names are prefixed `helix/` (`helix/goto-line`), so they can't collide with
  another plugin's commands.
- Top-level `define`s carry the same `helix/` prefix as house style, to set them apart from
  HUME builtins and Steel functions. `lint.sh` checks both.
- Bind only keys Helix itself binds, and only to a command that does what Helix's does or
  comes close. Unbind every HUME key Helix doesn't bind; a Helix key with no command that
  can be built stays unbound. Every `Ctrl` key Helix doesn't bind runs `helix/nothing`: the
  plugin finds those keys from its own binding tables, so a key bound there needs no extra
  step, while a HUME root key the plugin keeps goes in `helix/hume-root-keys`.
- Write the plugin in Steel. A behavior HUME's commands and API can't express goes in the
  README's Known limitations.
- Comments explain *why*, never *what*. `;;;` documents the definition below it; `;;` marks a
  section banner or an inline aside.
- If a change relies on a newer HUME API, bump `tests/lib.sh`'s `MIN_HUME_VERSION`,
  `plugin.scm`'s `hume-version>=?` check and its error message, and README's
  **Requirements** together; `lint.sh` checks they all match.
- A user-visible change adds a line under `## Unreleased` at the top of
  [CHANGELOG.md](CHANGELOG.md), creating that heading if it isn't there.

The rules for writing a HUME plugin are in HUME's
[Writing Plugins](https://cvlmtg.github.io/HUME/writing-plugins.html) manual.

## Pull requests

- One logical change per pull request.
- Rebase on `main` rather than merging it in; pull requests are squash-merged.

### Commit messages

[Conventional Commits](https://www.conventionalcommits.org), imperative mood, no trailing
period:

```
fix(words): keep the cursor's word when it starts the line
feat(keys): bind Alt-J
```

Types in use: `feat`, `fix`, `refactor`, `docs`, `test`, `style`, `chore`. Scope is optional:
`words`, `find`, `surround`, `keys`, `docs`, `tests`, `lint`, or `ci`.

The subject says what changed; the body says **why**.

## Verification

```sh
./scripts/lint.sh          # version drift, naming convention, whitespace
./tests/run.sh             # every case, driving a real hume headless
./tests/run.sh words       # only the named cases from tests/cases/
```

Each check runs `hume --keys`: HUME opens a file, replays a key stream with this working copy
loaded as the installed plugin, and saves the buffer, which the check compares byte for byte.
A motion is checked through the edit that follows it (`w` then `d` deletes what `w`
selected), and the head's side through `;` then an insert. `tests/config/stand-ins.scm`
defines stand-ins for the other plugins' commands, so the keys bound for them are checked
without those plugins.

`tests/run.sh` needs a `hume` binary, the first one found, in order: `$HUME_BIN`,
`$HUME_REPO` (built once with `cargo build -p hume-editor`), `hume` on `PATH`, or a sibling
checkout at `../hume`. CI (`.github/workflows/ci.yml`) runs both scripts against the newest
stable HUME release that ships `tests/lib.sh`'s `MIN_HUME_VERSION`, falling back to nightly
if none does.

## Releasing

1. Rename CHANGELOG.md's `## Unreleased` heading to `## [X.Y.Z] - YYYY-MM-DD`. A removed key
   binding, a renamed command or a higher minimum HUME version is a major bump; a new key a
   minor one; a fix a patch.
2. Check that CI on `main` is green.
3. Tag and push the tag: `git tag vX.Y.Z && git push origin vX.Y.Z`.

## Security

Please do not open a public issue for a security problem. Use GitHub's **Report a
vulnerability** button on the repository's Security tab, which opens a private advisory.
