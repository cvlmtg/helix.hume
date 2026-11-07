# helix.hume

[![ci](https://github.com/cvlmtg/helix.hume/actions/workflows/ci.yml/badge.svg)](https://github.com/cvlmtg/helix.hume/actions/workflows/ci.yml)

[Helix](https://helix-editor.com) keybindings for [HUME](https://github.com/cvlmtg/hume).
It binds every Helix key HUME has an action for: `v` for Extend mode, `w`/`e`/`b` selecting
from the cursor, `x` growing a line at a time, `f`/`t` selecting up to a character, Helix's
goto, match (surround included), view, window (`Ctrl-w`), Space and `]`/`[` keys, and its
Insert-mode editing keys. A Helix key HUME has no action for keeps its HUME meaning.

## Requirements

- HUME 0.19.0 or later.
- `core:stdlib`, loaded before this plugin; it refuses to load without it.

## Install

HUME reads its config from `~/.config/hume/init.scm` (`$XDG_CONFIG_HOME/hume/init.scm` if
set, `%APPDATA%\hume\init.scm` on Windows).

### New config

If you don't have an `init.scm` yet, create it with this content:

```scheme
(load-plugin! "core:stdlib")
(load-plugin! "core:lsp")
(load-plugin! "core:pickers")
(load-plugin! "core:plum")
(load-plugin! "cvlmtg/helix.hume")
(bind-key! 'normal "g n" "goto-next-buffer")
(bind-key! 'normal "g p" "goto-prev-buffer")
```

Then start HUME and run:

```
:plum-install-plugins
:reload-config
```

`:plum-install-plugins` clones the repo after `init.scm` has already run, so `:reload-config`
re-evaluates `init.scm` with the plugin on disk.

### Existing config

If you already have an `init.scm`, add these lines to it:

```scheme
(load-plugin! "cvlmtg/helix.hume")
(bind-key! 'normal "g n" "goto-next-buffer")
(bind-key! 'normal "g p" "goto-prev-buffer")
```

Before saving, check where they go:

- Your `init.scm` must load `core:stdlib` before this plugin. If it already has
  `(load-plugin! "core:stdlib")`, don't add it again; if not, add it above the plugin's line.
- `:plum-install-plugins` comes from `core:plum`. Add `(load-plugin! "core:plum")` only if
  it's missing.
- Put the plugin's line after `core:lsp`, `core:pickers` and `core:classic-paste`, if you
  load them: the plugin binds Helix's keys for their actions (`Space f`, `Space k`, `] d`,
  `=`, `Space p`, …) only when they are already loaded. Loading it last also lets its `z b`
  win over `core:pickers`' `z b`.

Then run `:plum-install-plugins` and `:reload-config` from inside HUME, as for a new config.

### Pinning a release

To stay on a release instead of the latest commit, pin its tag with `#:ref`:

```scheme
(load-plugin! "cvlmtg/helix.hume" #:ref "v1.0.0")
```

## Keys

| Mode | Key | Command | Effect |
|---|---|---|---|
| Normal | `v` | `toggle-extend` | Enter or leave Extend mode |
| Normal | `w` / `W` | `helix/next-word-start` / `helix/next-long-word-start` | From the cursor to the next word / WORD's start, then each next one with the whitespace after it |
| Normal | `e` / `E` | `helix/next-word-end` / `helix/next-long-word-end` | From the cursor to its word / WORD's end, then each next one with the whitespace before it |
| Normal | `b` / `B` | `helix/prev-word-start` / `helix/prev-long-word-start` | From the cursor back to its word / WORD's start, then each previous one |
| Normal | `x` | `select-line`, always extending | Select the line, then grow by a line on each press |
| Normal | `f` / `F` | `helix/find-forward` / `helix/find-backward` | Select from the cursor through the next / previous char |
| Normal | `t` / `T` | `helix/till-forward` / `helix/till-backward` | Select from the cursor up to the next / previous char |
| Normal | `Alt-.` | `helix/repeat-find` | Repeat the last find forward, selecting from the cursor |
| Normal | `;` | `collapse-selection` | Collapse to the cursor, staying in Extend mode |
| Normal | `Alt-;` | `flip-selections` | Swap each selection's ends |
| Normal | `Alt-,` | `remove-primary-selection` | Drop the primary selection |
| Normal | `Alt-C` | `copy-selection-on-prev-line` | Copy the selection onto the line above |
| Normal | `Alt-s` | `split-selection-on-newlines` | Split selections into lines |
| Normal | `Alt-J` | `join-lines-select-spaces` | Join lines, selecting the inserted spaces |
| Normal | `*` / `Alt-*` | `search-selection` | Search the selection |
| Normal | `` ` `` / ``Alt-` `` | `make-text-lowercase` / `make-text-uppercase` | Change case |
| Normal | `R` | `helix/replace-with-yanked` | Replace each selection with the last yank or delete |
| Normal | `Alt-d` | `delete-selection` | Delete without yanking |
| Normal | `Ctrl-x` | `decrement` | Decrement the number under each selection |
| Normal | `Ctrl-b` / `Ctrl-f` | `page-up` / `page-down` | Scroll a page |
| Normal | `g g` | `helix/goto-line` | First line, or the line a count names |
| Normal | `g a` | `goto-alternate-buffer` | Alternate buffer |
| Normal | `g r` | `lsp/references` | References, with `core:lsp` |
| Normal | `m m` | `goto-matching-pair` | Matching bracket or tag |
| Normal | `m s` + char | `surround-add` | Surround the selection with the pair for char |
| Normal | `m d` + char | `helix/surround-delete` | Delete the surrounding pair for char |
| Normal | `m r` + old + new | `helix/surround-replace` | Replace the surrounding pair for old with the pair for new |
| Normal | `m i T` / `m a T` | `inner-test` / `around-test` | Test text object, with Helix's letter |
| Normal | `m i e` / `m a e` | `inner-value` / `around-value` | Value text object, with Helix's letter |
| Normal | `z z` / `z c`, `z t`, `z b` | `center-view-on-cursor`, `top-view-on-cursor`, `bottom-view-on-cursor` | Align the view |
| Normal | `z` + `Ctrl-f`/`PageDown`, `Ctrl-b`/`PageUp`, `Ctrl-d`, `Ctrl-u` | `page-down`, `page-up`, `half-page-down`, `half-page-up` | Scroll |
| Normal | `Ctrl-w` / `Space w` + `w`, `v`, `s`, `h`/`j`/`k`/`l` or arrows, `q` | `pane-focus-next`, `pane-vsplit`, `pane-split`, `pane-focus-*`, `pane-close` | Window mode; each letter also with `Ctrl` |
| Normal | `Space y` | `yank` | Yank, which also reaches the clipboard |
| Normal | `Space R` | `helix/replace-with-clipboard` | Replace each selection with the clipboard |
| Normal | `Space f` / `F`, `b`, `g` | `pickers/files`, `pickers/buffers`, `pickers/git-modified` | Pickers, with `core:pickers` |
| Normal | `Space k`, `s` / `S`, `r`, `a` | `lsp/hover`, `lsp/document-symbols` / `lsp/workspace-symbols`, `lsp/rename`, `lsp/code-actions` | With `core:lsp` |
| Normal | `Space p` / `P` | `classic-paste/clipboard-after` / `classic-paste/clipboard-before` | Paste the clipboard, with `core:classic-paste` |
| Normal | `=` | `lsp/format-source` | Format, with `core:lsp` |
| Normal | `]` / `[` + `f`, `t`, `a`, `c`, `T`, `p` | `goto-next-*` / `goto-prev-*` | Function, class, argument, comment, test, paragraph |
| Normal | `] d` / `[ d` | `lsp/goto-next-diagnostic` / `lsp/goto-prev-diagnostic` | Diagnostics, with `core:lsp` |
| Normal | `] Space` / `[ Space` | `helix/add-newline-below` / `helix/add-newline-above` | Add blank lines, as many as the count |
| Insert | `Ctrl-h` / `Ctrl-d` / `Ctrl-j` | `helix/insert-backspace` / `helix/insert-delete` / `helix/insert-newline` | Backspace, Delete, Enter |
| Insert | `Alt-Backspace` | `delete-word-backward` | Delete the word before the cursor |
| Insert | `Ctrl-x` | `completion-trigger` | Show completions |

The plugin also sets `word-selects-whitespace` to `after`, so words take the whitespace after
them as in Helix. A `set-option!` of your own in `init.scm` still wins.

## What changes from HUME's keys

- Extend mode is on `v` instead of `e`.
- `m s` wraps the selection instead of selecting a surrounding pair, and `m w` does nothing.
- `m m` jumps to the matching bracket instead of selecting the word; `M M` still selects a
  WORD.
- `*` searches the selection instead of the word under the cursor.
- `[` and `]` start Helix's jumps instead of cycling the kill ring. To keep cycling, bind it
  in your `init.scm`, for example `(bind-key! 'normal "alt-[" "paste-ring-older")`.
- `Ctrl-x` decrements; `x` grows the line selection on its own.
- With `core:lsp` loaded, `=` formats; `Alt-.` repeats the last find instead.
- On a kitty terminal, `Ctrl-w`, `Ctrl-b` and `Ctrl-f` don't extend `w`, `b` and `f` for one
  motion, as they do in HUME.

A Helix key HUME has no action for keeps its HUME meaning, so loading the plugin never turns a
working key into a dead one: `S`, `X`, `K`, `G`, `~`, `Ctrl-s`, `g f`/`g t`/`g c`/`g b`,
`z j`/`z k`/`z m` and `Alt-u`/`Alt-U`, among others.

## Known limitations

- **With several cursors, `w`/`e`/`b` select each cursor's whole word**, not the part from the
  cursor, and `e` past a word doesn't take the whitespace before the next one. Every command
  moves all selections alike, while each cursor sits a different distance into its word, and
  a plugin can't set selections one by one.
- **`w`/`e` on whitespace** select the next word, where Helix's select the rest of the
  whitespace first.
- **`Alt-.` repeats forward only**, also after `F` or `T`.
- **`R` on a one-character selection inserts before it** instead of replacing it.
- **`g g` with a count doesn't extend in Extend mode.**
- **`Ctrl-c` stops a running `|`**, as in HUME, instead of toggling comments, which stay on
  `G G`. Helix's `Space c` is unbound.
- **Helix keys with no HUME action** stay unbound or keep HUME's meaning: `S` (split on a
  regex), `K`/`Alt-K` (keep or remove matching selections), `Alt-o`/`Alt-i`/`Alt-p`/`Alt-n`
  and the other syntax-tree selections, `Alt-(`/`Alt-)`, `Alt-:`, `Alt-x`, `X`, `~`,
  `Alt-c`, `!`/`Alt-!`/`Alt-|`/`$`, `Ctrl-s`, `g t`/`g c`/`g b` (window top, center,
  bottom), `g j`/`g k`, `g .`, `g m`, `g f`, `g w`, `g |`, `z j`/`z k`/`z m`, `Z`,
  `Space c`/`d`/`D`/`h`/`j`/`'`/`/`/`?`/`Y`, `] g`/`[ g`, `] D`/`[ D`, `Ctrl-w o`,
  `Ctrl-w H`/`J`/`K`/`L`, and Insert-mode `Ctrl-u`, `Ctrl-k`, `Ctrl-s` and `Alt-d`.

## Contributing

Bug reports and pull requests: see [CONTRIBUTING.md](CONTRIBUTING.md). Release notes are in
[CHANGELOG.md](CHANGELOG.md).
