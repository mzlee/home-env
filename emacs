; from the template file /lusr/share/udb/pub/dotfiles/emacs
;
; This is just to give you some idea of the things you can set
; in your .emacs file.  If you want to use any of these commands
; remove the ";" from in front of the line.

;; To change the font size under X.
; (set-default-font "9x15")

;; Set your term type to vt100
; (load "term/vt100")

;; When in text (or related mode) break the lines at 80 chars
; (setq text-mode-hook 'turn-on-auto-fill)
(setq fill-column 80)

;; Add installed modules
(add-to-list 'load-path "~/.emacs.d/site-lisp")
(add-to-list 'load-path "~/share/emacs/site-lisp")
(add-to-list 'load-path "/usr/share/emacs/site-lisp")

(require 'org-install)
(require 'yaml-mode)

(require 'org-velocity)
(setq org-velocity-bucket (expand-file-name "bucket.org" org-directory))
(global-set-key (kbd "C-c v") 'org-velocity-read)

;; Add auto modes
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
(add-to-list 'auto-mode-alist '("Makefrag\\." . makefile-gmake-mode))
(add-to-list 'auto-mode-alist '("Makefile\\." . makefile-gmake-mode))
(add-to-list 'auto-mode-alist '("emacs\\'" . emacs-lisp-mode))
(add-to-list 'auto-mode-alist '("bash" . shell-script-mode))

;; Org Mode keys
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

(global-font-lock-mode 1)                     ; for all buffers
(add-hook 'org-mode-hook 'turn-on-font-lock)  ; Org buffers only

(setq c-basic-offset 3)
(setq python-basic-offset 4)

(global-set-key [?\M-1] 'goto-line)
(global-set-key [?\M-5] 'query-replace-regexp)

(defun my-c-indent-setup ()
  (setq indent-tabs-mode nil)
  (setq c-basic-offset 3))

(defun my-py-indent-setup ()
  (setq indent-tabs-mode nil)
  (setq python-basic-offset 4))

(defun my-org-indent-setup ()
  (auto-fill-mode 1)
  (setq indent-tabs-mode nil))

(add-hook 'python-mode-hook 'my-py-indent-setup)
(add-hook 'c-mode-hook 'my-c-indent-setup)
(add-hook 'c++-mode-hook 'my-c-indent-setup)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
(add-hook 'html-mode-hook (setq tab-width 3))
(add-hook 'tex-mode-hook (auto-fill-mode 1))
(add-hook 'latex-mode-hook (auto-fill-mode 1))
(add-hook 'org-mode-hook 'my-org-indent-setup)

(put 'narrow-to-region 'disabled nil)

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(org-agenda-files nil))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )

;; Trying to define a new mode
;(defvar javascript-mode-font-lock-keywords
;   '(("\\(--.*\\)" 1 'font-lock-comment-face)))
(define-derived-mode javascript-mode java-mode "JavaScript"
  "Major mode to edit JavaScript files."
;  (set (make-local-variable 'font-lock-keywords)
;       '(javascript-mode-font-lock-keywords))
;  (set (make-local-variable 'comment-start) "--"))
  )
(add-to-list 'auto-mode-alist '("\\.js\\'" . javascript-mode))

(defvar user-temporary-file-directory
  (concat "/tmp/" user-login-name "/emacs.d/tmp"))
(make-directory user-temporary-file-directory t)
(setq backup-by-copying t)
(setq backup-directory-alist
	        `(("." . ,user-temporary-file-directory)
			          (,tramp-file-name-regexp nil)))
(setq auto-save-list-file-prefix
	        (concat user-temporary-file-directory ".auto-saves-"))
(setq auto-save-file-name-transforms
	        `((".*" ,user-temporary-file-directory t)))
