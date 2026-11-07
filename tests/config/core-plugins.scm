;;; The plugin after the core plugins whose commands it binds keys for, as the
;;; README's Install section loads them.
(load-plugin! "core:stdlib")
(load-plugin! "core:lsp")
(load-plugin! "core:pickers")
(load-plugin! "core:classic-paste")
(load-plugin! "@PLUGIN@")
