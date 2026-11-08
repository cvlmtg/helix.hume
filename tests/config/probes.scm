;;; The plugin plus probes for what a buffer can't show: Ctrl-t pastes the
;;; number of open panes, and `:test-insert` pastes its argument.
(load-plugin! "core:stdlib")
(load-plugin! "@PLUGIN@")
(define-command! "test/pane-count" "Paste the number of open panes."
  (lambda (pane) (paste-text! pane (number->string (length (panes))))))
(bind-key! 'normal "ctrl-t" "test/pane-count")
(define-typed-command! "test-insert" "Paste the argument."
  (lambda (pane arg) (paste-text! pane arg)))
