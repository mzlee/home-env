;;; init.el --- Custom init file.  Start breaking this down.

(require 'package)

(defvar root-dir (file-name-directory load-file-name)
  "The root dir of the Emacs distribution.")

(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/") t)
(setq package-user-dir (expand-file-name "elpa" root-dir))

(package-initialize)
;;; init.el ends here
