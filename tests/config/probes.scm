;;; The plugin plus probes for what a buffer can't show: Ctrl-t pastes the
;;; number of open panes, Ctrl-y shows a read-only view whose text changes on
;;; each press, `:test-insert` pastes its argument, and `:test-option` the
;;; value of the buffer option it names.
(load-plugin! "core:stdlib")
(load-plugin! "@PLUGIN@")
(define-command! "test/pane-count" "Paste the number of open panes."
  (lambda (pane) (paste-text! pane (number->string (length (panes))))))
(bind-key! 'normal "ctrl-t" "test/pane-count")
(define test/view-count 0)
(define-command! "test/show-view" "Show a read-only view, with new text each time."
  (lambda (pane)
    (set! test/view-count (+ test/view-count 1))
    (show-read-only-buffer! pane "probe" (number->string test/view-count))))
(bind-key! 'normal "ctrl-y" "test/show-view")
(define-typed-command! "test-insert" "Paste the argument."
  (lambda (pane arg) (paste-text! pane arg)))
(define-typed-command! "test-option" "Paste a buffer option's value."
  (lambda (pane arg) (paste-text! pane (get-buffer-option pane arg))))
