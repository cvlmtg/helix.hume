;;; cvlmtg/helix.hume — Helix keybindings for HUME.

(define helix/plugin "cvlmtg/helix.hume")

(unless (hume-version>=? 0 19 0)
  (error (string-append helix/plugin ": requires HUME 0.19.0 or later")))

(unless (member "core:stdlib" (declared-plugins))
  (error (string-append helix/plugin ": requires core:stdlib — (load-plugin! \"core:stdlib\") before (load-plugin! \"" helix/plugin "\")")))

;;; Helix's words take the whitespace after them. Set at plugin rank, so a
;;; `set-option!` in the user's init.scm still wins.
(set-option! "word-selects-whitespace" "after")

;; ── Shared helpers ────────────────────────────────────────────────────────────

(define (helix/char-at pane at)
  (string-ref (buffer-text pane #:range (hash 'start-char at 'end-char (+ at 1))) 0))

(define (helix/blank? ch)
  (and (char-whitespace? ch) (not (char=? ch #\newline))))

(define (helix/line-text pane line)
  (car (buffer-lines pane #:range (hash 'start-line line 'end-line (+ line 1)))))

(define (helix/line-length pane line)
  (string-length (helix/line-text pane line)))

(define (helix/dedupe xs)
  (cond ((null? xs) xs)
        ((member (car xs) (cdr xs)) (helix/dedupe (cdr xs)))
        (else (cons (car xs) (helix/dedupe (cdr xs))))))

(define (helix/index-where pred xs)
  (let loop ((xs xs) (i 0))
    (cond ((null? xs) #f)
          ((pred (car xs)) i)
          (else (loop (cdr xs) (+ i 1))))))

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

;;; For a lone bare cursor, its offset on a word or 'blank on whitespace
;;; other than a line break; 'several for several bare cursors; #f
;;; otherwise, and always with a count or in Extend mode. Several cursors
;;; get whole words: every command moves all selections alike, while each
;;; cursor sits a different distance into its word.
(define (helix/word-target pane count extend)
  (and (= count 0)
       (not extend)
       (let ((sels (buffer-selections pane)))
         (if (null? (cdr sels))
             (let* ((at (selection-head (car sels)))
                    (ch (helix/char-at pane at)))
               (cond ((not (= at (selection-anchor (car sels)))) #f)
                     ((helix/blank? ch) 'blank)
                     ((char-whitespace? ch) #f)
                     (else at)))
             (and (call! "stdlib/all-single-char?" sels) 'several)))))

(define (helix/start-at! pane cursor)
  (call! "flip-selections" pane)
  (if (< (helix/head pane) cursor)
      (helix/walk-head! pane "move-right" (lambda (at) (< at cursor)))
      (helix/walk-head! pane "move-left" (lambda (at) (> at cursor))))
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
            ((equal? target 'several) (call! object pane))
            ((equal? target 'blank)
             (helix/walk-head! pane "move-right"
                               (lambda (at) (helix/blank? (helix/char-at pane (+ at 1))))))
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
            ((equal? target 'several) (call! object pane))
            ((equal? target 'blank)
             (let ((cursor (helix/head pane)))
               (call! next pane count extend)
               (call! "trim-selection-whitespace" pane)
               (helix/start-at! pane cursor)))
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
            ((equal? target 'several) (call! object pane))
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

;;; Whether the last find or till went backward, for `Alt-.` to repeat it so.
(define helix/last-find-backward #f)

;;; Collapses onto the cursor, then runs the native motion extending, so the
;;; selection starts at the cursor; Extend mode keeps the selection and grows
;;; it, as Helix's does. A cancelled read changes nothing.
(define (helix/selecting-find native backward)
  (lambda (pane count extend)
    (on-next-char!
      (lambda (ch)
        (when ch
          (set! helix/last-find-backward backward)
          (unless extend (call! "collapse-selection" pane))
          (call! native pane count #t ch))))))

(define-command! "helix/find-forward"
  "Select from the cursor through the next occurrence of the next typed character."
  (helix/selecting-find "find-forward" #f))

(define-command! "helix/find-backward"
  "Select from the cursor back through the previous occurrence of the next typed character."
  (helix/selecting-find "find-backward" #t))

(define-command! "helix/till-forward"
  "Select from the cursor up to the next occurrence of the next typed character."
  (helix/selecting-find "till-forward" #f))

(define-command! "helix/till-backward"
  "Select from the cursor back to just after the previous occurrence of the next typed character."
  (helix/selecting-find "till-backward" #t))

(define-command! "helix/repeat-find"
  "Repeat the last find or till motion in its direction, selecting from the cursor."
  (lambda (pane count extend)
    (unless extend (call! "collapse-selection" pane))
    (call! (if helix/last-find-backward "repeat-find-backward" "repeat-find-forward") pane count #t)))

;; ── Goto ──────────────────────────────────────────────────────────────────────

;;; Goes to the start of `line`. Extend mode moves every head by the primary
;;; cursor's distance to that line, since a script can't place each head on
;;; its own.
(define (helix/goto-line! pane line extend)
  (if extend
      (let ((delta (- line (buffer-cursor-line pane))))
        (cond ((> delta 0) (call! "move-down" pane delta #t))
              ((< delta 0) (call! "move-up" pane (- delta) #t)))
        (call! "goto-line-start" pane 0 #t))
      (goto-location! pane (hash 'target pane 'char-offset (line->char-offset pane line)))))

;;; The line a count names, clamped to the last one.
(define (helix/count-line pane count)
  (min (- count 1) (- (buffer-line-count pane) 1)))

(define-command! "helix/goto-line"
  "Go to the line the count names, or to the first line without a count."
  (lambda (pane count extend)
    (helix/goto-line! pane (if (= count 0) 0 (helix/count-line pane count)) extend)))

;;; Helix's `G` never extends, and does nothing without a count.
(define-command! "helix/goto-line-count"
  "Go to the line the count names; without a count, do nothing."
  (lambda (pane count)
    (when (> count 0) (helix/goto-line! pane (helix/count-line pane count) #f))))

;;; Helix's `goto_window`: `pick` gets the view's first line, the offset of
;;; its last row, the scroll margin and the count less one, and names a line
;;; that is then kept clear of the margins.
(define (helix/goto-window! pane count extend pick)
  (let* ((view (viewport-range pane))
         (top (hash-ref view 'start-line))
         (last-row (- (hash-ref view 'end-line) top 1))
         (margin (min (get-option "scroll-margin") (quotient last-row 2)))
         (line (max (+ top margin)
                    (min (+ top (- last-row margin))
                         (pick top last-row margin (max 0 (- count 1)))))))
    (helix/goto-line! pane (min line (- (buffer-line-count pane) 1)) extend)))

(define-command! "helix/goto-window-top"
  "Go to the first line of the view past the scroll margin, or that many lines below it."
  (lambda (pane count extend)
    (helix/goto-window! pane count extend
      (lambda (top last-row margin skip) (+ top margin skip)))))

(define-command! "helix/goto-window-center"
  "Go to the middle line of the view."
  (lambda (pane count extend)
    (helix/goto-window! pane count extend
      (lambda (top last-row margin skip) (+ top (quotient last-row 2))))))

(define-command! "helix/goto-window-bottom"
  "Go to the last line of the view before the scroll margin, or that many lines above it."
  (lambda (pane count extend)
    (helix/goto-window! pane count extend
      (lambda (top last-row margin skip) (- (+ top last-row) margin skip)))))

(define-command! "helix/move-line-down"
  "Move down by buffer lines, not wrapped rows."
  (lambda (pane count extend) (call! "move-down" pane (max count 1) extend)))

(define-command! "helix/move-line-up"
  "Move up by buffer lines, not wrapped rows."
  (lambda (pane count extend) (call! "move-up" pane (max count 1) extend)))

;;; Extending `select-line` widens each selection to its lines but leaves it
;;; forward; Helix keeps the direction, which only a flip of every selection
;;; can restore.
(define-command! "helix/extend-to-line-bounds"
  "Extend each selection to cover whole lines."
  (lambda (pane)
    (unless (selections-linewise? pane)
      (let ((backward (not (call! "stdlib/find"
                                  (lambda (sel) (>= (selection-head sel) (selection-anchor sel)))
                                  (buffer-selections pane)))))
        (call! "select-line" pane 0 #t)
        (when backward (call! "flip-selections" pane))))))

;; ── Edits ─────────────────────────────────────────────────────────────────────

(define (helix/selection-text pane sel)
  (buffer-text pane #:range (hash 'start-char (selection-start-char sel)
                                  'end-char (selection-end-char sel))))

(define (helix/selection-texts pane)
  (map (lambda (sel) (helix/selection-text pane sel)) (buffer-selections pane)))

;;; Rewrites every selection in one edit. `parts` holds a (before selected
;;; after) triple of strings per selection, in `buffer-selections` order, and
;;; `selected` must not be empty. Each selection's text becomes the three
;;; joined, with `selected` selected in the selection's direction. An end
;;; lands at the start of the edited range holding it, and a cursor at an
;;; insertion moves past it, so the selection's text is replaced in two ranges split
;;; at the later end. On a one-character selection both ends share one
;;; range, and the cursor lands on the last character of `selected`.
(define (helix/rewrite-selections! pane parts)
  (edit-text! pane
    (apply append
      (map (lambda (sel part)
             (let* ((start (selection-start-char sel))
                    (last (max (selection-anchor sel) (selection-head sel)))
                    (selected (cadr part))
                    (n (string-length selected)))
               (when (= n 0)
                 (error "helix/rewrite-selections!: empty selected text"))
               (list (hash 'start-char start 'end-char start 'text (car part))
                     (hash 'start-char start 'end-char last 'text (substring selected 0 (- n 1)))
                     (hash 'start-char last 'end-char (selection-end-char sel)
                           'text (string-append (substring selected (- n 1) n) (caddr part))))))
           (buffer-selections pane)
           parts))))

(define (helix/replace-selections! pane texts)
  (helix/rewrite-selections! pane (map (lambda (text) (list "" text "")) texts)))

;;; One register string per selection when the counts match, all of them
;;; joined otherwise, as `p` places a register.
(define (helix/replace-with-register pane name)
  (let ((values (read-register name))
        (sels (buffer-selections pane)))
    (when values
      (helix/replace-selections! pane
        (if (= (length values) (length sels))
            values
            (let ((joined (apply string-append values)))
              (map (lambda (sel) joined) sels)))))))

(define-command! "helix/change-noyank"
  "Delete each selection without yanking it and enter Insert mode."
  (lambda (pane)
    (set-register-prefix! "b")
    (call! "change" pane)))

(define-command! "helix/yank-main-to-clipboard"
  "Copy the primary selection to the system clipboard."
  (lambda (pane)
    (write-register! "c"
      (list (helix/selection-text pane (call! "stdlib/primary-selection" (buffer-selections pane)))))))

(define (helix/switch-char-case ch)
  (let ((upper (char-upcase ch)))
    (if (char=? upper ch) (char-downcase ch) upper)))

(define-command! "helix/switch-case"
  "Swap the case of every character in each selection."
  (lambda (pane)
    (helix/replace-selections! pane
      (map (lambda (text) (list->string (map helix/switch-char-case (string->list text))))
           (helix/selection-texts pane)))))

;;; Moves each selection's text `steps` selections forward, wrapping around.
(define (helix/rotate-contents! pane steps)
  (let* ((texts (helix/selection-texts pane))
         (n (length texts))
         (k (modulo (- n (modulo steps n)) n)))
    (helix/replace-selections! pane (append (list-tail texts k) (take texts k)))))

(define-command! "helix/rotate-selection-contents-forward"
  "Move each selection's text to the next selection, the last one's to the first."
  (lambda (pane count) (helix/rotate-contents! pane (max count 1))))

(define-command! "helix/rotate-selection-contents-backward"
  "Move each selection's text to the previous selection, the first one's to the last."
  (lambda (pane count) (helix/rotate-contents! pane (- (max count 1)))))

(define-command! "helix/replace-with-yanked"
  "Replace each selection with the last yanked or deleted text."
  (lambda (pane) (helix/replace-with-register pane "k")))

(define-command! "helix/replace-with-clipboard"
  "Replace each selection with the system clipboard."
  (lambda (pane) (helix/replace-with-register pane "c")))

;; ── Files and panes ───────────────────────────────────────────────────────────

(define (helix/path-char? ch)
  (not (or (char-whitespace? ch)
           (memv ch '(#\" #\' #\` #\( #\) #\[ #\] #\{ #\} #\< #\> #\, #\;)))))

;;; The run of path characters around offset `at` on its line, or #f.
(define (helix/path-at pane at)
  (let* ((line (char-offset->line pane at))
         (text (helix/line-text pane line))
         (col (- at (line->char-offset pane line)))
         (n (string-length text)))
    (and (< col n)
         (helix/path-char? (string-ref text col))
         (let ((start (let loop ((i col))
                        (if (and (> i 0) (helix/path-char? (string-ref text (- i 1)))) (loop (- i 1)) i)))
               (end (let loop ((i col))
                      (if (and (< i n) (helix/path-char? (string-ref text i))) (loop (+ i 1)) i))))
           (substring text start end)))))

;;; A lone bare cursor names the path around it; otherwise each selection
;;; names one with its text.
(define (helix/selected-paths pane)
  (let ((sels (buffer-selections pane)))
    (if (and (null? (cdr sels)) (= (selection-anchor (car sels)) (selection-head (car sels))))
        (let ((path (helix/path-at pane (selection-head (car sels)))))
          (if path (list path) '()))
        (filter (lambda (path) (> (string-length path) 0))
                (map trim (helix/selection-texts pane))))))

;;; A relative path is taken from the buffer's own directory, as Helix does,
;;; and from the working directory for a buffer with no file.
(define (helix/resolve-path pane path)
  (let ((home (home-dir))
        (file (buffer-path pane)))
    (cond ((and home (starts-with? path "~/"))
           (path-join home (substring path 2 (string-length path))))
          ((call! "stdlib/path-absolute?" path) path)
          (else (path-join (if file (parent-name file) (cwd)) path)))))

(define (helix/open-file! path)
  (if (is-dir? path)
      (log! 'error (string-append path " is a directory"))
      (switch-to-buffer! (focused-pane) (open-buffer! path))))

(define (helix/goto-file! pane open)
  (let ((paths (map (lambda (path) (helix/resolve-path pane path)) (helix/selected-paths pane))))
    (if (null? paths)
        (log! 'error "no file path under the cursor")
        (for-each open paths))))

(define-command! "helix/goto-file"
  "Open the file path under the cursor, or each selected path."
  (lambda (pane) (helix/goto-file! pane helix/open-file!)))

(define-command! "helix/goto-file-hsplit"
  "Open the file path under the cursor, or each selected path, in a stacked split."
  (lambda (pane) (helix/goto-file! pane (call! "stdlib/with-split" helix/open-file!))))

(define-command! "helix/goto-file-vsplit"
  "Open the file path under the cursor, or each selected path, in a side-by-side split."
  (lambda (pane) (helix/goto-file! pane (call! "stdlib/with-vsplit" helix/open-file!))))

;;; Pane commands act on the focused pane only, so this cycles focus and closes
;;; each other pane it reaches. Two steps that both land back on the starting
;;; pane mean it is the only one left.
(define-command! "helix/pane-only"
  "Close every pane of the tab but the focused one."
  (lambda (pane)
    (let ((start (focused-pane)))
      (let loop ((back-once #f))
        (call! "pane-focus-next" (focused-pane))
        (cond ((not (equal? (focused-pane) start))
               (call! "pane-close" (focused-pane))
               (loop #f))
              ((not back-once) (loop #t)))))))

;; ── Changes and diagnostics ───────────────────────────────────────────────────

;;; The buffer's hunks against its file's text in git's HEAD, or #f when it
;;; has no file or git has no such file.
(define (helix/git-hunks pane)
  (let ((file (buffer-path pane)))
    (and file
         (let ((result (run-capture! "git" (list "-C" (parent-name file) "show"
                                                 (string-append "HEAD:./" (file-name file))))))
           (and (equal? (hash-ref result 'exit) 0)
                (hash-ref (diff-buffer-lines pane (hash-ref result 'stdout)) 'hunks))))))

;;; Selects a hunk's lines, or puts a cursor where lines were removed.
(define (helix/select-hunk! pane hunk)
  (let ((start (min (hash-ref hunk 'new-start-line) (- (buffer-line-count pane) 1)))
        (lines (- (hash-ref hunk 'new-end-line) (hash-ref hunk 'new-start-line))))
    (goto-location! pane (hash 'target pane 'char-offset (line->char-offset pane start)))
    (when (> lines 0)
      (call! "select-line" pane 0 #f)
      (let loop ((left (- lines 1)))
        (when (> left 0)
          (call! "select-line" pane 0 #t)
          (loop (- left 1)))))))

;;; `pick` gets the hunks and the cursor's line and returns a hunk or #f.
(define (helix/goto-change! pane pick)
  (let ((hunks (helix/git-hunks pane)))
    (if hunks
        (let ((hunk (pick hunks (buffer-cursor-line pane))))
          (when hunk (helix/select-hunk! pane hunk)))
        (log! 'info "no git base for this buffer"))))

;;; The `count`-th of `hunks`, or the last when there are fewer.
(define (helix/nth-or-last hunks count)
  (and (pair? hunks) (list-ref hunks (min (- (max count 1) 1) (- (length hunks) 1)))))

(define-command! "helix/goto-next-change"
  "Select the next change against git's HEAD, or the count-th next."
  (lambda (pane count)
    (helix/goto-change! pane
      (lambda (hunks line)
        (helix/nth-or-last (filter (lambda (h) (> (hash-ref h 'new-start-line) line)) hunks) count)))))

(define-command! "helix/goto-prev-change"
  "Select the previous change against git's HEAD, or the count-th previous."
  (lambda (pane count)
    (helix/goto-change! pane
      (lambda (hunks line)
        (helix/nth-or-last (reverse (filter (lambda (h) (< (hash-ref h 'new-start-line) line)) hunks))
                           count)))))

(define-command! "helix/goto-first-change"
  "Select the first change against git's HEAD."
  (lambda (pane)
    (helix/goto-change! pane (lambda (hunks line) (and (pair? hunks) (car hunks))))))

(define-command! "helix/goto-last-change"
  "Select the last change against git's HEAD."
  (lambda (pane)
    (helix/goto-change! pane (lambda (hunks line) (helix/nth-or-last (reverse hunks) 1)))))

(define (helix/goto-diagnostic! pane pick)
  (let ((diagnostics (diagnostics-for-buffer pane)))
    (when (pair? diagnostics)
      (goto-location! pane (hash 'target pane 'char-offset (hash-ref (pick diagnostics) 'start-char))))))

(define-command! "helix/goto-first-diagnostic"
  "Go to the buffer's first diagnostic."
  (lambda (pane) (helix/goto-diagnostic! pane car)))

(define-command! "helix/goto-last-diagnostic"
  "Go to the buffer's last diagnostic."
  (lambda (pane)
    (helix/goto-diagnostic! pane (lambda (diagnostics) (list-ref diagnostics (- (length diagnostics) 1))))))

;;; Picker rows for a buffer's diagnostics, each carrying the buffer and the
;;; diagnostic's offset.
(define (helix/diagnostic-items buffer)
  (let ((name (or (buffer-display-path buffer #:relative (cwd)) (buffer-name buffer))))
    (map (lambda (d)
           (cons (string-append name ":" (number->string (+ (hash-ref d 'start-line) 1))
                                ":" (number->string (+ (hash-ref d 'grapheme-col) 1))
                                " " (symbol->string (hash-ref d 'severity))
                                " " (string-replace (hash-ref d 'message) "\n" " "))
                 (cons buffer (hash-ref d 'start-char))))
         (diagnostics-for-buffer buffer))))

(define (helix/goto-diagnostic-item payload)
  (when payload
    (goto-location! (focused-pane) (hash 'target (car payload) 'char-offset (cdr payload)))))

(define (helix/diagnostics-picker! pane items)
  (if (null? items)
      (log! 'info "no diagnostics")
      (picker! pane items (call! "stdlib/picker-keymap" helix/goto-diagnostic-item)
               #:prompt "diagnostics: ")))

(define-command! "helix/diagnostics-picker"
  "Pick one of this buffer's diagnostics and go to it."
  (lambda (pane) (helix/diagnostics-picker! pane (helix/diagnostic-items pane))))

(define-command! "helix/workspace-diagnostics-picker"
  "Pick one of the diagnostics of every open buffer and go to it."
  (lambda (pane)
    (helix/diagnostics-picker! pane (apply append (map helix/diagnostic-items (buffers))))))

;; ── History ───────────────────────────────────────────────────────────────────

;;; Moves `steps` revisions along the undo history in the order the revisions
;;; were made, stopping at either end with a message.
(define (helix/step-history! pane steps)
  (let* ((tree (buffer-undo-tree pane))
         (here (helix/index-where (lambda (rev) (hash-ref rev 'current?)) tree))
         (wanted (+ here steps))
         (target (max 0 (min (- (length tree) 1) wanted))))
    (unless (= target here)
      (goto-revision! pane (hash-ref (list-ref tree target) 'id)))
    (unless (= target wanted)
      (log! 'info (if (< steps 0) "Already at oldest change" "Already at newest change")))))

(define-command! "helix/earlier"
  "Go back the count of revisions in the order they were made, across undo branches."
  (lambda (pane count) (helix/step-history! pane (- (max count 1)))))

(define-command! "helix/later"
  "Go forward the count of revisions in the order they were made, across undo branches."
  (lambda (pane count) (helix/step-history! pane (max count 1))))

;;; Buffer key → char offset of the buffer's last change.
(define helix/last-edits (hash))

;;; Pane values of the buffers changed so far, most recently changed first.
(define helix/modified-buffers '())

;;; Where a hunk's change starts in the new text: its first changed word, else
;;; the column its first removed word had, else the start of its line.
(define (helix/hunk-offset pane hunk)
  (let* ((words (hash-ref hunk 'words))
         (new (if words (hash-ref words 'new) '()))
         (old (if words (hash-ref words 'old) '()))
         (line (min (hash-ref hunk 'new-start-line) (- (buffer-line-count pane) 1))))
    (if (pair? new)
        (hash-ref (car new) 'start-char)
        (+ (line->char-offset pane line)
           (if (pair? old)
               (min (hash-ref (car old) 'start-char-col) (helix/line-length pane line))
               0)))))

(define (helix/forget-buffer pane)
  (set! helix/last-edits (hash-remove helix/last-edits (buffer-key pane)))
  (set! helix/modified-buffers
        (filter (lambda (other) (not (equal? (buffer-key other) (buffer-key pane))))
                helix/modified-buffers)))

(register-hook! 'on-text-changed
  (lambda (pane changes)
    (helix/forget-buffer pane)
    (set! helix/modified-buffers (cons pane helix/modified-buffers))
    (when (pair? changes)
      (set! helix/last-edits
            (hash-insert helix/last-edits (buffer-key pane) (helix/hunk-offset pane (car changes)))))))

(register-hook! 'on-buffer-close helix/forget-buffer)

(define-command! "helix/goto-last-modification"
  "Go to where the buffer was last changed."
  (lambda (pane)
    (let ((offset (hash-try-get helix/last-edits (buffer-key pane))))
      (when offset
        (goto-location! pane (hash 'target pane
                                   'char-offset (min offset (- (buffer-char-count pane) 1))))))))

(define-command! "helix/goto-last-modified-file"
  "Switch to the most recently changed buffer other than this one."
  (lambda (pane)
    (let ((target (call! "stdlib/find"
                         (lambda (other)
                           (and (buffer-live? other)
                                (not (equal? (buffer-key other) (buffer-key pane)))))
                         helix/modified-buffers)))
      (if target
          (switch-to-buffer! pane target)
          (log! 'error "no last modified buffer")))))

;; ── Filtering selections ──────────────────────────────────────────────────────

(define (helix/spans pane)
  (map (lambda (sel) (cons (selection-start-char sel) (selection-end-char sel)))
       (buffer-selections pane)))

;;; Removes the selections starting at one of `starts`. A script can only
;;; remove the primary selection, so the primary is cycled onto each in turn.
(define (helix/drop-selections! pane starts)
  (let loop ()
    (let* ((sels (buffer-selections pane))
           (target (helix/index-where (lambda (sel) (memv (selection-start-char sel) starts)) sels)))
      (when target
        (let cycle ((steps (modulo (- target (helix/index-where selection-primary? sels)) (length sels))))
          (when (> steps 0)
            (call! "cycle-primary-forward" pane)
            (cycle (- steps 1))))
        (call! "remove-primary-selection" pane)
        (loop)))))

;;; Steel has no regex, so `sift-within` finds the matches: it drops the
;;; selections with none and narrows the rest, and `undo-selection-change`
;;; then restores them. When nothing changes, either no selection matched or
;;; each matched whole, and both leave every selection in place.
(define (helix/filter-selections! pane label keep-matching)
  (prompt! pane label
    (lambda (pattern)
      (when (and pattern (> (string-length pattern) 0))
        (let ((before (helix/spans pane)))
          (call! "sift-within" pane pattern)
          (let ((after (helix/spans pane)))
            (unless (equal? after before)
              (call! "undo-selection-change" pane)
              (let* ((matched? (lambda (span)
                                 (call! "stdlib/find"
                                        (lambda (m) (and (>= (car m) (car span)) (<= (cdr m) (cdr span))))
                                        after)))
                     (drop (map car (filter (lambda (span)
                                              (if keep-matching (not (matched? span)) (matched? span)))
                                            before))))
                (if (= (length drop) (length before))
                    (log! 'error "no selections remaining")
                    (helix/drop-selections! pane drop))))))))))

(define-command! "helix/keep-selections"
  "Keep only the selections a regex matches inside."
  (lambda (pane) (helix/filter-selections! pane "keep:" #t)))

(define-command! "helix/remove-selections"
  "Remove the selections a regex matches inside."
  (lambda (pane) (helix/filter-selections! pane "remove:" #f)))

;; ── Shell output ──────────────────────────────────────────────────────────────

;;; Runs the command typed at the prompt once, through the `shell` option, and
;;; rewrites each selection with `place` applied to its text and the output,
;;; less one trailing line break as Helix strips it.
(define (helix/shell-output! pane label place)
  (prompt! pane label
    (lambda (command)
      (when command
        (let* ((shell (get-option "shell"))
               (result (run-capture! (car shell) (append (cdr shell) (list command))))
               (out (hash-ref result 'stdout))
               (n (string-length out))
               (out (if (and (> n 0) (char=? (string-ref out (- n 1)) #\newline))
                        (substring out 0 (- n 1))
                        out)))
          (cond ((not (equal? (hash-ref result 'exit) 0))
                 (log! 'error (string-append command ": " (hash-ref result 'stderr))))
                ((> (string-length out) 0)
                 (helix/rewrite-selections! pane
                   (map (lambda (text) (place text out)) (helix/selection-texts pane))))))))))

(define-command! "helix/shell-insert-output"
  "Insert a shell command's output before each selection."
  (lambda (pane)
    (helix/shell-output! pane "insert-output:" (lambda (text out) (list "" out text)))))

(define-command! "helix/shell-append-output"
  "Append a shell command's output after each selection."
  (lambda (pane)
    (helix/shell-output! pane "append-output:" (lambda (text out) (list text out "")))))

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

;;; One edit inserting the line breaks at the start of the line after each
;;; selection's last line (below), or of its first line (above), so every
;;; selection stays on its text. The last line has no next line: its breaks
;;; go at the end of the text.
(define (helix/add-blank-lines pane count below)
  (let* ((last (- (buffer-line-count pane) 1))
         (edge (if below max min))
         (lines (helix/dedupe
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

;;; Merges overlapping (start . end) ranges, sorted by start.
(define (helix/merge-ranges ranges)
  (cond ((or (null? ranges) (null? (cdr ranges))) ranges)
        ((< (car (cadr ranges)) (cdr (car ranges)))
         (helix/merge-ranges (cons (cons (car (car ranges)) (max (cdr (car ranges)) (cdr (cadr ranges))))
                                   (cddr ranges))))
        (else (cons (car ranges) (helix/merge-ranges (cdr ranges))))))

;;; Deletes, in one edit, the (start . end) range `span` gives for each
;;; cursor's offset.
(define (helix/delete-at-cursors! pane span)
  (edit-text! pane
    (map (lambda (range) (hash 'start-char (car range) 'end-char (cdr range) 'text ""))
         (helix/merge-ranges
           (map (lambda (sel) (span (selection-head sel))) (buffer-selections pane))))))

;;; From past the first non-blank, back to it; from it or before, back to the
;;; line start; from the line start, back over the line break before it.
(define-command! "helix/kill-to-line-start"
  "Delete back to the line's first non-blank, else to its start, else join the line above."
  (lambda (pane)
    (helix/delete-at-cursors! pane
      (lambda (at)
        (let* ((line (char-offset->line pane at))
               (start (line->char-offset pane line))
               (text (helix/line-text pane line))
               (blanks (let loop ((i 0))
                         (if (and (< i (string-length text)) (helix/blank? (string-ref text i)))
                             (loop (+ i 1))
                             i))))
          (cond ((> at (+ start blanks)) (cons (+ start blanks) at))
                ((> at start) (cons start at))
                ((> line 0) (cons (- at 1) at))
                (else (cons at at))))))))

(define-command! "helix/kill-to-line-end"
  "Delete to the line's end, or join the next line from there."
  (lambda (pane)
    (helix/delete-at-cursors! pane
      (lambda (at)
        (let* ((line (char-offset->line pane at))
               (end (+ (line->char-offset pane line) (helix/line-length pane line))))
          (if (< at end) (cons at end) (cons at (+ at 1))))))))

;;; A character is a word character when HUME's own word splitting keeps it,
;;; so the buffer's `word-chars` setting counts.
(define (helix/word-char? pane ch)
  (pair? (call! "stdlib/split-words" pane (string ch))))

;;; Skips whitespace, line breaks included, then a run of word characters or
;;; a run of other non-blank ones.
(define-command! "helix/delete-word-forward"
  "Delete to the end of the next word."
  (lambda (pane)
    (helix/delete-at-cursors! pane
      (lambda (at)
        (let* ((line (char-offset->line pane at))
               (stop (if (< (+ line 2) (buffer-line-count pane))
                         (line->char-offset pane (+ line 2))
                         (buffer-char-count pane)))
               (text (buffer-text pane #:range (hash 'start-char at 'end-char stop)))
               (n (string-length text))
               (skip (lambda (i keep?)
                       (let loop ((i i))
                         (if (and (< i n) (keep? (string-ref text i))) (loop (+ i 1)) i))))
               (word (skip 0 char-whitespace?))
               (end (cond ((= word n) n)
                          ((helix/word-char? pane (string-ref text word))
                           (skip word (lambda (ch) (helix/word-char? pane ch))))
                          (else
                           (skip word (lambda (ch) (not (or (char-whitespace? ch)
                                                            (helix/word-char? pane ch)))))))))
          (cons at (+ at end)))))))

(define-command! "helix/insert-word-under-cursor"
  "Insert the word under the cursor."
  (lambda (pane)
    (let ((word (symbol-under-cursor pane)))
      (unless (equal? word "") (paste-text! pane word)))))

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

(define helix/normal-bindings
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
    ("~" "helix/switch-case")
    ("alt-)" "helix/rotate-selection-contents-forward")
    ("alt-(" "helix/rotate-selection-contents-backward")
    ("!" "helix/shell-insert-output")
    ("alt-!" "helix/shell-append-output")
    ("K" "helix/keep-selections")
    ("alt-K" "helix/remove-selections")
    ("alt-d" "delete-selection")
    ("alt-c" "helix/change-noyank")
    ("ctrl-x" "decrement")
    ("ctrl-b" "page-up")
    ("ctrl-f" "page-down")
    ("tab" "jump-forward")
    ("G" "helix/goto-line-count")
    ("g g" "helix/goto-line")
    ("g a" "goto-alternate-buffer")
    ("g t" "helix/goto-window-top")
    ("g c" "helix/goto-window-center")
    ("g b" "helix/goto-window-bottom")
    ("g j" "helix/move-line-down")
    ("g k" "helix/move-line-up")
    ("X" "helix/extend-to-line-bounds")
    ("alt-u" "helix/earlier")
    ("alt-U" "helix/later")
    ("g ." "helix/goto-last-modification")
    ("g m" "helix/goto-last-modified-file")
    ("g f" "helix/goto-file")
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
    ("space Y" "helix/yank-main-to-clipboard")
    ("space c" "toggle-comment")
    ("space alt-c" "toggle-comment")
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
    ("] g" "helix/goto-next-change")
    ("[ g" "helix/goto-prev-change")
    ("] G" "helix/goto-last-change")
    ("[ G" "helix/goto-first-change")
    ("] D" "helix/goto-last-diagnostic")
    ("[ D" "helix/goto-first-diagnostic")
    ("space d" "helix/diagnostics-picker")
    ("space D" "helix/workspace-diagnostics-picker")
    ("] space" "helix/add-newline-below")
    ("[ space" "helix/add-newline-above")))

(define helix/present-bindings
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
    ("space /" "grep/picker")
    ("g r" "lsp/references")
    ("=" "lsp/format-source")
    ("] d" "lsp/goto-next-diagnostic")
    ("[ d" "lsp/goto-prev-diagnostic")))

;;; HUME's and the eager core plugins' keys that Helix doesn't have. A Ctrl
;;; key whose bare key is a root key is left to the Ctrl bindings below.
(define helix/non-helix-keys
  '("shift-tab" "#" "{" "}" "-" "=" "S" "M"
    "g u" "g U" "g v" "g V" "g x" "g X" "g F" "g T" "g A" "g C"
    "m w" "m /" "m u" "m U" "m i i" "m i u" "m a u" "m i v" "m a v" "m i l" "m a l"
    "z j" "z k" "z f" "z m" "ctrl-V"))

(for-each (lambda (key) (unbind-key! 'normal key)) helix/non-helix-keys)
(helix/bind-all! 'normal helix/normal-bindings)
(bind-key-extend! 'normal "x" "select-line")

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
    ("ctrl-q" "pane-close")
    ("o" "helix/pane-only")
    ("ctrl-o" "helix/pane-only")
    ("f" "helix/goto-file-hsplit")
    ("F" "helix/goto-file-vsplit")))

(helix/bind-all! 'normal (helix/under "ctrl-w" helix/window-bindings))
(helix/bind-all! 'normal (helix/under "space w" helix/window-bindings))

(helix/bind-all! 'insert
  '(("ctrl-h" "helix/insert-backspace")
    ("ctrl-d" "helix/insert-delete")
    ("ctrl-j" "helix/insert-newline")
    ("alt-backspace" "delete-word-backward")
    ("ctrl-x" "completion-trigger")
    ("pageup" "page-up")
    ("pagedown" "page-down")
    ("ctrl-u" "helix/kill-to-line-start")
    ("ctrl-k" "helix/kill-to-line-end")
    ("alt-d" "helix/delete-word-forward")
    ("alt-delete" "helix/delete-word-forward")))

(unbind-key! 'insert "ctrl-space")
(unbind-key! 'insert "ctrl-|")

(bind-key! 'command "ctrl-s" "helix/insert-word-under-cursor")

(helix/bind-present! helix/present-bindings)

;; ── Ctrl keys ─────────────────────────────────────────────────────────────────
;; On a kitty terminal, a Ctrl key with no binding of its own runs the bare
;; key's command extending, so Ctrl-j extends a line down. Helix gives Ctrl
;; keys no such meaning, so every root key's Ctrl form is bound to a command
;; that does nothing, except the Ctrl keys Helix binds.

(define-command! "helix/nothing"
  "Do nothing, as Helix does for this key."
  (lambda (pane) #t))

;;; The root keys HUME binds and the plugin keeps.
(define helix/hume-root-keys
  '("h" "j" "k" "l" "left" "right" "up" "down" "home" "end" "pageup" "pagedown"
    "x" "%" "," "(" ")" "C" "_" "d" "J" "&" ">" "lt" "c" "y" "p" "P" "u" "U" "r"
    "." "/" "?" "n" "N" "s" "|" ":" "i" "a" "I" "A" "o" "O"))

;;; The keys whose Ctrl form keeps its binding: Helix's, and Ctrl-c, which
;;; stays HUME's `cancel-pipe`.
(define helix/helix-ctrl-keys '("b" "f" "u" "d" "i" "o" "a" "x" "c" "w"))

(define (helix/first-key keys)
  (let loop ((i 0))
    (cond ((= i (string-length keys)) keys)
          ((char=? (string-ref keys i) #\space) (substring keys 0 i))
          (else (loop (+ i 1))))))

(define (helix/modified-key? key)
  (and (> (string-length key) 1) (memv #\- (string->list key))))

(for-each (lambda (key) (bind-key! 'normal (string-append "ctrl-" key) "helix/nothing"))
          (filter (lambda (key) (not (or (helix/modified-key? key) (member key helix/helix-ctrl-keys))))
                  (helix/dedupe
                    (append helix/hume-root-keys
                            (map (lambda (b) (helix/first-key (car b)))
                                 (append helix/normal-bindings helix/present-bindings))))))
