;;; Stand-ins for the other plugins' commands the plugin binds keys for: each
;;; pastes its own name, so a check sees which command a key ran.
(load-plugin! "core:stdlib")
(for-each
  (lambda (name)
    (define-command! name "stand-in" (lambda (pane) (paste-text! pane name))))
  '("pickers/files" "pickers/buffers" "pickers/git-modified"
    "lsp/hover" "lsp/document-symbols" "lsp/workspace-symbols" "lsp/rename"
    "lsp/code-actions" "lsp/references" "lsp/format-source"
    "lsp/goto-next-diagnostic" "lsp/goto-prev-diagnostic"
    "classic-paste/clipboard-after" "classic-paste/clipboard-before"
    "grep/picker"))
(load-plugin! "@PLUGIN@")
