# helix.hume

[![ci](https://github.com/cvlmtg/helix.hume/actions/workflows/ci.yml/badge.svg)](https://github.com/cvlmtg/helix.hume/actions/workflows/ci.yml)

[Helix](https://helix-editor.com) keybindings for [HUME](https://github.com/cvlmtg/hume).
It binds every Helix key it can build from HUME's commands: `v` for Extend mode, `w`/`e`/`b`
selecting from the cursor, `x` growing a line at a time, `f`/`t` selecting up to a character,
`K` and `~`, `!` and `R`, Helix's goto, match (surround included), view, window (`Ctrl-w`),
Space and `]`/`[` keys, and its Insert-mode editing keys. A Helix key it can't build keeps its
HUME meaning.

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
(bind-key! 'normal "K" "helix/keep-selections")
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
(bind-key! 'normal "K" "helix/keep-selections")
```

Before saving, check where they go:

- Your `init.scm` must load `core:stdlib` before this plugin. If it already has
  `(load-plugin! "core:stdlib")`, don't add it again; if not, add it above the plugin's line.
- `:plum-install-plugins` comes from `core:plum`. Add `(load-plugin! "core:plum")` only if
  it's missing.
- Put the plugin's line after `core:lsp`, `core:pickers`, `core:classic-paste` and
  `cvlmtg/grep.hume`, if you load them: the plugin binds Helix's keys for their actions
  (`Space f`, `Space k`, `] d`, `=`, `Space p`, `Space /`, …) only when they are already
  loaded. Loading it last also lets its `z b` win over `core:pickers`' `z b`.
- The `g n`, `g p` and `K` lines are there because `core:lsp`, which loads after your
  `init.scm`, binds those keys to its own commands; a binding in `init.scm` wins over it.

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
| Normal | `X` | `helix/extend-to-line-bounds` | Extend each selection to whole lines |
| Normal | `f` / `F` | `helix/find-forward` / `helix/find-backward` | Select from the cursor through the next / previous char |
| Normal | `t` / `T` | `helix/till-forward` / `helix/till-backward` | Select from the cursor up to the next / previous char |
| Normal | `Alt-.` | `helix/repeat-find` | Repeat the last find in its direction, selecting from the cursor |
| Normal | `;` | `collapse-selection` | Collapse to the cursor, staying in Extend mode |
| Normal | `Alt-;` | `flip-selections` | Swap each selection's ends |
| Normal | `Alt-,` | `remove-primary-selection` | Drop the primary selection |
| Normal | `K` / `Alt-K` | `helix/keep-selections` / `helix/remove-selections` | Keep / remove the selections a regex matches inside |
| Normal | `Alt-C` | `copy-selection-on-prev-line` | Copy the selection onto the line above |
| Normal | `Alt-s` | `split-selection-on-newlines` | Split selections into lines |
| Normal | `Alt-J` | `join-lines-select-spaces` | Join lines, selecting the inserted spaces |
| Normal | `*` / `Alt-*` | `search-selection` | Search the selection |
| Normal | `~` | `helix/switch-case` | Swap the case of each character |
| Normal | `` ` `` / ``Alt-` `` | `make-text-lowercase` / `make-text-uppercase` | Change case |
| Normal | `R` | `helix/replace-with-yanked` | Replace each selection with the last yank or delete |
| Normal | `Alt-(` / `Alt-)` | `helix/rotate-selection-contents-backward` / `-forward` | Move each selection's text to the previous / next selection |
| Normal | `!` / `Alt-!` | `helix/shell-insert-output` / `helix/shell-append-output` | Insert a shell command's output before / after each selection |
| Normal | `Alt-d` | `delete-selection` | Delete without yanking |
| Normal | `Alt-c` | `helix/change-noyank` | Change without yanking |
| Normal | `Alt-u` / `Alt-U` | `helix/earlier` / `helix/later` | Step back / forward through the undo history in the order it was made, across branches |
| Normal | `Ctrl-x` | `decrement` | Decrement the number under each selection |
| Normal | `Ctrl-b` / `Ctrl-f` | `page-up` / `page-down` | Scroll a page |
| Normal | `g g` | `helix/goto-line` | First line, or the line a count names |
| Normal | `g t` / `g c` / `g b` | `helix/goto-window-top` / `-center` / `-bottom` | Top, middle or bottom line of the view |
| Normal | `g j` / `g k` | `helix/move-line-down` / `helix/move-line-up` | Move by lines of the file, not wrapped rows |
| Normal | `g f` | `helix/goto-file` | Open the path under the cursor, or each selected path |
| Normal | `g a` | `goto-alternate-buffer` | Alternate buffer |
| Normal | `g m` | `helix/goto-last-modified-file` | The buffer changed last, other than this one |
| Normal | `g .` | `helix/goto-last-modification` | Where this buffer was changed last |
| Normal | `g r` | `lsp/references` | References, with `core:lsp` |
| Normal | `m m` | `goto-matching-pair` | Matching bracket or tag |
| Normal | `m s` + char | `surround-add` | Surround the selection with the pair for char |
| Normal | `m d` + char | `helix/surround-delete` | Delete the surrounding pair for char |
| Normal | `m r` + old + new | `helix/surround-replace` | Replace the surrounding pair for old with the pair for new |
| Normal | `m i T` / `m a T` | `inner-test` / `around-test` | Test text object, with Helix's letter |
| Normal | `m i e` / `m a e` | `inner-value` / `around-value` | Value text object, with Helix's letter |
| Normal | `z z` / `z c`, `z t`, `z b` | `center-view-on-cursor`, `top-view-on-cursor`, `bottom-view-on-cursor` | Align the view |
| Normal | `z` + `Ctrl-f`/`PageDown`, `Ctrl-b`/`PageUp`, `Ctrl-d`, `Ctrl-u` | `page-down`, `page-up`, `half-page-down`, `half-page-up` | Scroll |
| Normal | `Ctrl-w` / `Space w` + `w`, `v`, `s`, `h`/`j`/`k`/`l` or arrows, `q`, `o` | `pane-focus-next`, `pane-vsplit`, `pane-split`, `pane-focus-*`, `pane-close`, `helix/pane-only` | Window mode; each letter also with `Ctrl` |
| Normal | `Ctrl-w` / `Space w` + `f` / `F` | `helix/goto-file-hsplit` / `helix/goto-file-vsplit` | Open the path under the cursor in a stacked / side-by-side split |
| Normal | `Space y` | `yank` | Yank, which also reaches the clipboard |
| Normal | `Space Y` | `helix/yank-main-to-clipboard` | Copy the primary selection to the clipboard |
| Normal | `Space R` | `helix/replace-with-clipboard` | Replace each selection with the clipboard |
| Normal | `Space c` / `Space Alt-c` | `toggle-comment` | Comment or uncomment the lines |
| Normal | `Space d` / `Space D` | `helix/diagnostics-picker` / `helix/workspace-diagnostics-picker` | Pick a diagnostic of this buffer / of every open buffer |
| Normal | `Space f` / `F`, `b`, `g` | `pickers/files`, `pickers/buffers`, `pickers/git-modified` | Pickers, with `core:pickers` |
| Normal | `Space /` | `grep/picker` | Search the files, with [grep.hume](https://github.com/cvlmtg/grep.hume) |
| Normal | `Space k`, `s` / `S`, `r`, `a` | `lsp/hover`, `lsp/document-symbols` / `lsp/workspace-symbols`, `lsp/rename`, `lsp/code-actions` | With `core:lsp` |
| Normal | `Space p` / `P` | `classic-paste/clipboard-after` / `classic-paste/clipboard-before` | Paste the clipboard, with `core:classic-paste` |
| Normal | `=` | `lsp/format-source` | Format, with `core:lsp` |
| Normal | `]` / `[` + `f`, `t`, `a`, `c`, `T`, `p` | `goto-next-*` / `goto-prev-*` | Function, class, argument, comment, test, paragraph |
| Normal | `] g` / `[ g`, `] G` / `[ G` | `helix/goto-next-change` / `helix/goto-prev-change`, `helix/goto-last-change` / `helix/goto-first-change` | Select a change against git's last commit |
| Normal | `] d` / `[ d` | `lsp/goto-next-diagnostic` / `lsp/goto-prev-diagnostic` | Diagnostics, with `core:lsp` |
| Normal | `] D` / `[ D` | `helix/goto-last-diagnostic` / `helix/goto-first-diagnostic` | Last / first diagnostic |
| Normal | `] Space` / `[ Space` | `helix/add-newline-below` / `helix/add-newline-above` | Add blank lines, as many as the count |
| Insert | `Ctrl-h` / `Ctrl-d` / `Ctrl-j` | `helix/insert-backspace` / `helix/insert-delete` / `helix/insert-newline` | Backspace, Delete, Enter |
| Insert | `Alt-Backspace` | `delete-word-backward` | Delete the word before the cursor |
| Insert | `Alt-d` / `Alt-Delete` | `helix/delete-word-forward` | Delete to the end of the next word |
| Insert | `Ctrl-u` / `Ctrl-k` | `helix/kill-to-line-start` / `helix/kill-to-line-end` | Delete to the line's start or end, joining lines from either end |
| Insert | `PageUp` / `PageDown` | `page-up` / `page-down` | Scroll a page |
| Insert | `Ctrl-x` | `completion-trigger` | Show completions |
| `:` prompt | `Ctrl-s` | `helix/insert-word-under-cursor` | Insert the word under the cursor |

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
- `X` extends selections to whole lines instead of selecting the line backward.
- `g f`, `g t` and `g c` open a file and go to the top and middle of the view instead of
  jumping to the next function, class and comment, which stay on `] f`, `] t` and `] c`.
- `K` keeps the selections a regex matches, also with `core:lsp` loaded once your `init.scm`
  binds it as [Install](#install) shows; `lsp/hover` stays on `Space k`.
- `Ctrl-u`, `Ctrl-k` and `Alt-d` delete text in Insert mode.
- On a kitty terminal, `Ctrl-w`, `Ctrl-b` and `Ctrl-f` don't extend `w`, `b` and `f` for one
  motion, as they do in HUME.

A Helix key the plugin can't build keeps its HUME meaning, so loading the plugin never turns a
working key into a dead one: `S`, `G`, `Ctrl-s`, `z j`/`z k`/`z m` and `Q`/`q`, among others.

## Known limitations

- **With several cursors, `w`/`e`/`b` select each cursor's whole word**, not the part from the
  cursor, and `e` past a word doesn't take the whitespace before the next one. Every command
  moves all selections alike, while each cursor sits a different distance into its word, and
  a plugin can't set selections one by one.
- **On a one-character selection, `R`, `Space R`, `Alt-(`/`Alt-)` and `!`/`Alt-!` leave the
  cursor on the new text's last character** instead of selecting all of it.
- **`K` and `Alt-K` change nothing when every selection is a single character.**
- **In Extend mode with several selections, `g g` with a count and `g t`/`g c`/`g b` move each
  head as far as the primary one's**, where Helix's put every head on the same line. `g .`,
  `] g`/`[ g` and `] D`/`[ D` don't extend.
- **`] g` and the other change keys compare against git's last commit** on every press, where
  Helix keeps the diff it shows in the gutter. A file git doesn't track has no changes.
- **`Space D` lists the diagnostics of open buffers only.**
- **`g f` on a directory reports an error** instead of opening a file picker there, and it
  opens a URL as a file path.
- **`Ctrl-c` stops a running `|`**, as in HUME, instead of toggling comments, which are on
  `Space c` and `G G`.
- **Helix keys a plugin can't build** stay unbound or keep HUME's meaning:
  - `S` (split on a regex): Steel has no regex, and HUME can only narrow selections to the
    matches.
  - `Alt-x`, `Alt-:`, `Alt--` and `Alt-_`: a plugin can't set a selection's ends.
  - `Alt-o`/`Alt-i`/`Alt-p`/`Alt-n` and the other syntax-tree selections: HUME gives plugins
    no syntax tree.
  - `Alt-|` and `$`: a plugin can't give a command input.
  - `Ctrl-s` (save the selection to the jumplist), `Space j`, `Space '`, `Space ?`, `Space h`,
    `Space C` and Insert-mode `Ctrl-s`: HUME has nothing to build them on.
  - `z j`/`z k`/`z m` and `Z`: HUME can't scroll the view by a line.
  - `g w`: a plugin can't draw labels over the text.
  - `Ctrl-w H`/`J`/`K`/`L`: HUME rotates panes but can't swap two.
  - `Q`/`q`: HUME's macros are on `Q Q` and `q q`.

## Contributing

Bug reports and pull requests: see [CONTRIBUTING.md](CONTRIBUTING.md). Release notes are in
[CHANGELOG.md](CHANGELOG.md).
