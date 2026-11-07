;;; cvlmtg/helix.hume — Helix keybindings for HUME.

(define helix/plugin "cvlmtg/helix.hume")

(unless (hume-version>=? 0 19 0)
  (error (string-append helix/plugin ": requires HUME 0.19.0 or later")))

(unless (member "core:stdlib" (declared-plugins))
  (error (string-append helix/plugin ": requires core:stdlib — (load-plugin! \"core:stdlib\") before (load-plugin! \"" helix/plugin "\")")))

;;; Helix's words take the whitespace after them. Set at plugin rank, so a
;;; `set-option!` in the user's init.scm still wins.
(set-option! "word-selects-whitespace" "after")

;; ── Words ─────────────────────────────────────────────────────────────────────
;; Helix's w/e/b select from the cursor: on a bare cursor inside a word, w
;; takes the rest of the word and the whitespace after it, e the rest of the
;; word, b the part back to the word's start. HUME's word commands select
;; whole words, and a script can neither set a selection nor count clusters,
;; so these start from a whole-word object and move one end to the cursor a
;; cluster at a time. Counting chars instead would overshoot on a combining
;; mark, since motions step by cluster.

(define (helix/head pane)
  (selection-head (car (buffer-selections pane))))

;;; Steps every head one cluster with `move` while `go?` holds for the first
;;; head, stopping at a step that leaves it in place (a line or buffer edge).
(define (helix/walk-head! pane move go?)
  (let loop ((at (helix/head pane)))
    (when (go? at)
      (call! move pane 1 #t)
      (let ((next (helix/head pane)))
        (unless (= next at) (loop next))))))

(define (helix/on-blank? pane at)
  (char-whitespace?
    (string-ref (buffer-text pane #:range (hash 'start-char at 'end-char (+ at 1))) 0)))

;;; The cursor's offset for a lone bare cursor on a word, 'several for
;;; several bare cursors, #f otherwise; a count or Extend mode is always #f.
;;; Several cursors get whole words: every command moves all selections
;;; alike, while each cursor sits a different distance into its word.
(define (helix/word-target pane count extend)
  (and (= count 0)
       (not extend)
       (let ((sels (buffer-selections pane)))
         (if (null? (cdr sels))
             (let ((at (selection-head (car sels))))
               (and (= at (selection-anchor (car sels)))
                    (not (helix/on-blank? pane at))
                    at))
             (and (call! "stdlib/all-single-char?" sels) 'several)))))

(define (helix/start-at! pane cursor)
  (call! "flip-selections" pane)
  (helix/walk-head! pane "move-right" (lambda (at) (< at cursor)))
  (call! "flip-selections" pane))

;;; Moves the start back to the cluster after `from`, the head the step began
;;; at, so `e` takes the whitespace before the next word as Helix's does.
(define (helix/start-after! pane from)
  (call! "flip-selections" pane)
  (helix/walk-head! pane "move-left" (lambda (at) (> at from)))
  (when (<= (helix/head pane) from) (call! "move-right" pane 1 #t))
  (call! "flip-selections" pane))

(define (helix/next-end! pane count extend next)
  (let ((from (helix/head pane))
        (single (null? (cdr (buffer-selections pane)))))
    (call! next pane count extend)
    (call! "trim-selection-whitespace" pane)
    (when (and single (not extend)) (helix/start-after! pane from))))

(define (helix/word-start object next)
  (lambda (pane count extend)
    (let ((target (helix/word-target pane count extend)))
      (cond ((number? target) (call! object pane) (helix/start-at! pane target))
            (target (call! object pane))
            (else (call! next pane count extend))))))

;;; On a word's last character Helix's `e` moves on to the next word.
(define (helix/word-end object next)
  (lambda (pane count extend)
    (let ((target (helix/word-target pane count extend)))
      (cond ((number? target)
             (call! object pane)
             (if (= (helix/head pane) target)
                 (helix/next-end! pane count extend next)
                 (helix/start-at! pane target)))
            (target (call! object pane))
            (else (helix/next-end! pane count extend next))))))

;;; HUME's previous-word commands leave a forward selection; Helix's `b`
;;; leaves the head on the word's start. Extend mode keeps HUME's direction,
;;; since flipping there would change which end grows.
(define (helix/prev-start! pane count extend prev)
  (call! prev pane count extend)
  (unless extend (call! "flip-selections" pane)))

;;; On a word's first character Helix's `b` moves to the previous word.
(define (helix/word-back object prev)
  (lambda (pane count extend)
    (let ((target (helix/word-target pane count extend)))
      (cond ((number? target)
             (call! object pane)
             (if (= (selection-anchor (car (buffer-selections pane))) target)
                 (helix/prev-start! pane count extend prev)
                 (begin
                   (helix/walk-head! pane "move-left" (lambda (at) (> at target)))
                   (call! "flip-selections" pane))))
            (target (call! object pane))
            (else (helix/prev-start! pane count extend prev))))))

(define-command! "helix/next-word-start"
  "Select from a bare cursor to the next word's start, else the next word with the whitespace after it."
  (helix/word-start "select-word" "select-next-word"))

(define-command! "helix/next-word-end"
  "Select from a bare cursor to its word's end, else the next word with the whitespace before it."
  (helix/word-end "inner-word" "select-next-word"))

(define-command! "helix/prev-word-start"
  "Select from a bare cursor back to its word's start, else the previous word."
  (helix/word-back "inner-word" "select-prev-word"))

(define-command! "helix/next-long-word-start"
  "Select from a bare cursor to the next WORD's start, else the next WORD with the whitespace after it."
  (helix/word-start "select-uppercase-word" "select-next-uppercase-word"))

(define-command! "helix/next-long-word-end"
  "Select from a bare cursor to its WORD's end, else the next WORD with the whitespace before it."
  (helix/word-end "inner-uppercase-word" "select-next-uppercase-word"))

(define-command! "helix/prev-long-word-start"
  "Select from a bare cursor back to its WORD's start, else the previous WORD."
  (helix/word-back "inner-uppercase-word" "select-prev-uppercase-word"))

;; ── Selecting find ────────────────────────────────────────────────────────────
;; Helix's f/t/F/T select from the cursor to the target, HUME's only move.

;;; Collapses onto the cursor, then runs the native motion extending, so the
;;; selection starts at the cursor; Extend mode keeps the selection and grows
;;; it, as Helix's does. A cancelled read changes nothing.
(define (helix/selecting-find native)
  (lambda (pane count extend)
    (on-next-char!
      (lambda (ch)
        (when ch
          (unless extend (call! "collapse-selection" pane))
          (call! native pane count #t ch))))))

(define-command! "helix/find-forward"
  "Select from the cursor through the next occurrence of the next typed character."
  (helix/selecting-find "find-forward"))

(define-command! "helix/find-backward"
  "Select from the cursor back through the previous occurrence of the next typed character."
  (helix/selecting-find "find-backward"))

(define-command! "helix/till-forward"
  "Select from the cursor up to the next occurrence of the next typed character."
  (helix/selecting-find "till-forward"))

(define-command! "helix/till-backward"
  "Select from the cursor back to just after the previous occurrence of the next typed character."
  (helix/selecting-find "till-backward"))

(define-command! "helix/repeat-find"
  "Repeat the last find or till motion forward, selecting from the cursor."
  (lambda (pane count extend)
    (unless extend (call! "collapse-selection" pane))
    (call! "repeat-find-forward" pane count #t)))

;; ── Goto ──────────────────────────────────────────────────────────────────────

(define-command! "helix/goto-line"
  "Go to the line the count names, or to the first line without a count."
  (lambda (pane count extend)
    (if (= count 0)
        (call! "goto-first-line" pane count extend)
        (let ((line (min (- count 1) (- (buffer-line-count pane) 1))))
          (goto-location! pane (hash 'target pane 'char-offset (line->char-offset pane line)))))))

;; ── Edits ─────────────────────────────────────────────────────────────────────

(define (helix/replace-with-register pane name)
  (let ((text (read-register name)))
    (when text (paste-text! pane text))))

(define-command! "helix/replace-with-yanked"
  "Replace each selection with the last yanked or deleted text."
  (lambda (pane) (helix/replace-with-register pane "k")))

(define-command! "helix/replace-with-clipboard"
  "Replace each selection with the system clipboard."
  (lambda (pane) (helix/replace-with-register pane "c")))

;; ── Surround ──────────────────────────────────────────────────────────────────

;;; The native `surround-*` command that selects the pair for a delimiter,
;;; opening or closing. #f for any other character, and for the #f a
;;; cancelled read hands back, so callers skip it.
(define (helix/surround-cmd-for ch)
  (cond
    ((memv ch '(#\( #\))) "surround-paren")
    ((memv ch '(#\[ #\])) "surround-bracket")
    ((memv ch '(#\{ #\})) "surround-brace")
    ((memv ch '(#\< #\>)) "surround-angle")
    ((eqv? ch #\")         "surround-double-quote")
    ((eqv? ch #\')         "surround-single-quote")
    ((eqv? ch #\`)         "surround-backtick")
    (else #f)))

;;; Selects the pair as two cursors, then deletes them. Not #:repeatable:
;;; `.` repeats the `delete` the callback ran, on the pair the recorded
;;; selection steps find.
(define-command! "helix/surround-delete"
  "Delete the surrounding delimiter pair (md + char)."
  (lambda (pane)
    (on-next-char!
      (lambda (ch)
        (let ((cmd (helix/surround-cmd-for ch)))
          (when cmd
            (call! cmd pane)
            (call! "delete" pane)))))))

;;; Selects the pair, then reads the new character for `replace`, which maps
;;; it onto each end: `[` over a `(` pair gives `[` and `]`.
(define-command! "helix/surround-replace"
  "Replace the surrounding delimiter pair (mr + old_char + new_char)."
  (lambda (pane)
    (on-next-char!
      (lambda (ch)
        (let ((cmd (helix/surround-cmd-for ch)))
          (when cmd
            (call! cmd pane)
            (on-next-char!
              (lambda (new)
                (when new (call! "replace" pane new))))))))))

;; ── Blank lines ───────────────────────────────────────────────────────────────

(define (helix/dedupe-sorted xs)
  (cond ((null? xs) xs)
        ((null? (cdr xs)) xs)
        ((= (car xs) (cadr xs)) (helix/dedupe-sorted (cdr xs)))
        (else (cons (car xs) (helix/dedupe-sorted (cdr xs))))))

;;; One edit inserting the line breaks at the start of the line after each
;;; selection's last line (below), or of its first line (above), so every
;;; selection stays on its text. The last line has no next line: its breaks
;;; go at the end of the text.
(define (helix/add-blank-lines pane count below)
  (let* ((last (- (buffer-line-count pane) 1))
         (edge (if below max min))
         (lines (helix/dedupe-sorted
                  (map (lambda (sel)
                         (char-offset->line pane (edge (selection-anchor sel) (selection-head sel))))
                       (buffer-selections pane))))
         (insert-at (lambda (line)
                      (cond ((not below) (line->char-offset pane line))
                            ((< line last) (line->char-offset pane (+ line 1)))
                            (else (buffer-char-count pane)))))
         (breaks (make-string (max 1 count) #\newline)))
    (edit-text! pane
      (map (lambda (line)
             (let ((at (insert-at line)))
               (hash 'start-char at 'end-char at 'text breaks)))
           lines))))

(define-command! "helix/add-newline-below"
  "Add a blank line below each selection's last line, or as many as the count."
  (lambda (pane count) (helix/add-blank-lines pane count #t)))

(define-command! "helix/add-newline-above"
  "Add a blank line above each selection's first line, or as many as the count."
  (lambda (pane count) (helix/add-blank-lines pane count #f)))

;; ── Insert mode ───────────────────────────────────────────────────────────────

(define-command! "helix/insert-backspace"
  "Delete before the cursor, as Backspace does."
  (lambda (pane) (insert-key! pane "backspace")))

(define-command! "helix/insert-delete"
  "Delete under the cursor, as Delete does."
  (lambda (pane) (insert-key! pane "delete")))

(define-command! "helix/insert-newline"
  "Break the line, as Enter does."
  (lambda (pane) (insert-key! pane "enter")))

;; ── Key bindings ──────────────────────────────────────────────────────────────

(define (helix/bind-all! mode bindings)
  (for-each (lambda (b) (bind-key! mode (car b) (cadr b))) bindings))

;;; Binds keys for another plugin's commands only when that plugin is loaded,
;;; so a config without it gets neither the keys nor an unknown-command
;;; warning for each. A lazy plugin's declared commands count.
(define (helix/bind-present! bindings)
  (for-each (lambda (b)
              (when (command-exists? (cadr b))
                (bind-key! 'normal (car b) (cadr b))))
            bindings))

(define (helix/under prefix bindings)
  (map (lambda (b) (list (string-append prefix " " (car b)) (cadr b))) bindings))

(helix/bind-all! 'normal
  '(("v" "toggle-extend")
    ("w" "helix/next-word-start")
    ("W" "helix/next-long-word-start")
    ("e" "helix/next-word-end")
    ("E" "helix/next-long-word-end")
    ("b" "helix/prev-word-start")
    ("B" "helix/prev-long-word-start")
    ("f" "helix/find-forward")
    ("F" "helix/find-backward")
    ("t" "helix/till-forward")
    ("T" "helix/till-backward")
    ("alt-." "helix/repeat-find")
    (";" "collapse-selection")
    ("alt-;" "flip-selections")
    ("alt-," "remove-primary-selection")
    ("alt-C" "copy-selection-on-prev-line")
    ("alt-s" "split-selection-on-newlines")
    ("alt-J" "join-lines-select-spaces")
    ("*" "search-selection")
    ("alt-*" "search-selection")
    ("`" "make-text-lowercase")
    ("alt-`" "make-text-uppercase")
    ("R" "helix/replace-with-yanked")
    ("alt-d" "delete-selection")
    ("ctrl-x" "decrement")
    ("ctrl-b" "page-up")
    ("ctrl-f" "page-down")
    ("g g" "helix/goto-line")
    ("g a" "goto-alternate-buffer")
    ("m m" "goto-matching-pair")
    ("m s" "surround-add")
    ("m d" "helix/surround-delete")
    ("m r" "helix/surround-replace")
    ("m i T" "inner-test")
    ("m a T" "around-test")
    ("m i e" "inner-value")
    ("m a e" "around-value")
    ("z z" "center-view-on-cursor")
    ("z c" "center-view-on-cursor")
    ("z t" "top-view-on-cursor")
    ("z b" "bottom-view-on-cursor")
    ("z ctrl-f" "page-down")
    ("z pagedown" "page-down")
    ("z ctrl-b" "page-up")
    ("z pageup" "page-up")
    ("z ctrl-d" "half-page-down")
    ("z ctrl-u" "half-page-up")
    ("space y" "yank")
    ("space R" "helix/replace-with-clipboard")
    ("] f" "goto-next-function")
    ("[ f" "goto-prev-function")
    ("] t" "goto-next-class")
    ("[ t" "goto-prev-class")
    ("] a" "goto-next-argument")
    ("[ a" "goto-prev-argument")
    ("] c" "goto-next-comment")
    ("[ c" "goto-prev-comment")
    ("] T" "goto-next-test")
    ("[ T" "goto-prev-test")
    ("] p" "goto-next-paragraph")
    ("[ p" "goto-prev-paragraph")
    ("] space" "helix/add-newline-below")
    ("[ space" "helix/add-newline-above")))

(bind-key-extend! 'normal "x" "select-line")
(unbind-key! 'normal "m w")

(define helix/window-bindings
  '(("w" "pane-focus-next")
    ("ctrl-w" "pane-focus-next")
    ("v" "pane-vsplit")
    ("ctrl-v" "pane-vsplit")
    ("s" "pane-split")
    ("ctrl-s" "pane-split")
    ("h" "pane-focus-left")
    ("ctrl-h" "pane-focus-left")
    ("left" "pane-focus-left")
    ("j" "pane-focus-down")
    ("ctrl-j" "pane-focus-down")
    ("down" "pane-focus-down")
    ("k" "pane-focus-up")
    ("ctrl-k" "pane-focus-up")
    ("up" "pane-focus-up")
    ("l" "pane-focus-right")
    ("ctrl-l" "pane-focus-right")
    ("right" "pane-focus-right")
    ("q" "pane-close")
    ("ctrl-q" "pane-close")))

(helix/bind-all! 'normal (helix/under "ctrl-w" helix/window-bindings))
(helix/bind-all! 'normal (helix/under "space w" helix/window-bindings))

(helix/bind-all! 'insert
  '(("ctrl-h" "helix/insert-backspace")
    ("ctrl-d" "helix/insert-delete")
    ("ctrl-j" "helix/insert-newline")
    ("alt-backspace" "delete-word-backward")
    ("ctrl-x" "completion-trigger")))

(helix/bind-present!
  '(("space f" "pickers/files")
    ("space F" "pickers/files")
    ("space b" "pickers/buffers")
    ("space g" "pickers/git-modified")
    ("space k" "lsp/hover")
    ("space s" "lsp/document-symbols")
    ("space S" "lsp/workspace-symbols")
    ("space r" "lsp/rename")
    ("space a" "lsp/code-actions")
    ("space p" "classic-paste/clipboard-after")
    ("space P" "classic-paste/clipboard-before")
    ("g r" "lsp/references")
    ("=" "lsp/format-source")
    ("] d" "lsp/goto-next-diagnostic")
    ("[ d" "lsp/goto-prev-diagnostic")))
