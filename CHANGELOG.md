# Changelog

## Unreleased

Requires HUME 0.19.0 or later and `core:stdlib`.

- Helix's keys for every HUME action that matches one: Extend mode on `v`; `w`/`e`/`b`
  selecting from the cursor; `x` growing by lines; `f`/`t`/`F`/`T` selecting up to a
  character and `Alt-.` repeating them; the goto, match (surround included), view, window,
  Space and `]`/`[` keys; and the Insert-mode `Ctrl-h`, `Ctrl-d`, `Ctrl-j`, `Ctrl-x` and
  `Alt-Backspace`.
- Keys for `core:lsp`, `core:pickers` and `core:classic-paste` actions are bound when those
  plugins are loaded first.
- Sets `word-selects-whitespace` to `after`, as Helix's words take the whitespace after them.
- Takes over HUME's `core:helix-surround`: `m s`, `m d` and `m r` surround as in Helix.
