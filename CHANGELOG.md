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
- Selection keys: `X`, `K`/`Alt-K`, `~`, `Alt-(`/`Alt-)`, `Alt-c`, and `!`/`Alt-!` inserting a
  shell command's output.
- History keys: `Alt-u`/`Alt-U` stepping through every undo branch, `g .` and `g m`.
- Goto and window keys: `g t`/`g c`/`g b`, `g j`/`g k`, `g f`, and `Ctrl-w` / `Space w` with
  `o`, `f` and `F`.
- `] g`/`[ g`/`] G`/`[ G` selecting changes against git's last commit, `] D`/`[ D`, and the
  `Space d`/`Space D` diagnostics pickers.
- `Space c`/`Space Alt-c` toggle comments and `Space Y` copies the primary selection to the
  clipboard. `Space /` opens grep.hume's picker when it is loaded first.
- Insert-mode `Ctrl-u`, `Ctrl-k`, `Alt-d`/`Alt-Delete` and `PageUp`/`PageDown`, and `Ctrl-s`
  on the `:` prompt.
- `G` goes to the line a count names, and `Tab` jumps forward, as `Ctrl-i` does.
- HUME's keys that Helix doesn't have are unbound, core:pickers' `z f`/`z m` and
  core:classic-paste's `Ctrl-v`/`Ctrl-Shift-v` included, and on a kitty terminal a `Ctrl` key
  Helix doesn't bind does nothing instead of extending the key's motion.
- Helix's typed commands HUME doesn't already have: `:open`, `:buffer-close` and its other and
  all forms, `:hsplit`/`:vs` and the `-new` splits, `:g`, the yank-join and clipboard commands,
  `:insert-output`/`:append-output`, `:sh`, `:read`, `:reflow`, `:diffget`, `:indent-style`,
  `:line-ending`, `:lang`, `:toggle`, `:change-current-directory`, `:show-directory`, `:char`,
  `:yank-diagnostic`, and `:format` with `core:lsp`.
- `Space p`/`Space P` paste the clipboard without `core:classic-paste`.
