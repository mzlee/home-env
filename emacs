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
; (setq fill-column 80)

; Set soft tabs

;; Locally installed files
;(setq load-path (cons "~/share/emacs/site-lisp" load-path))
;(require 'org-install)

;(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
;(global-set-key "\C-cl" 'org-store-link)
;(global-set-key "\C-ca" 'org-agenda)
;(global-set-key "\C-cb" 'org-iswitchb)

;(global-font-lock-mode 1)                     ; for all buffers
;(add-hook 'org-mode-hook 'turn-on-font-lock)  ; Org buffers only

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

(add-hook 'python-mode-hoo 'my-py-indent-setup)
(add-hook 'c-mode-hook 'my-c-indent-setup)
(add-hook 'c++-mode-hook 'my-c-indent-setup)

;(require 'yaml-mode)
;(add-to-list 'auto-mode-alist '("\\.yml$" . yaml-mode))

(add-hook 'html-mode-hool
		  (setq tab-width 3))

;(put 'narrow-to-region 'disabled nil)
