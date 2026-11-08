;;; The plugin after the core plugins whose commands it binds keys for, and
;;; the bindings core:lsp would take over, as the README's Install section
;;; has them.
(load-plugin! "core:stdlib")
(load-plugin! "core:lsp")
(load-plugin! "core:pickers")
(load-plugin! "core:classic-paste")
(load-plugin! "@PLUGIN@")
(bind-key! 'normal "g n" "goto-next-buffer")
(bind-key! 'normal "g p" "goto-prev-buffer")
(bind-key! 'normal "K" "helix/keep-selections")
(bind-key! 'normal "G" "helix/goto-line-count")
