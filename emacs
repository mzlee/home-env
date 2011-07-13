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

;; Add installed modules
(setq load-path (cons "~/share/emacs/site-lisp" load-path))
(require 'org-install)
(require 'yaml-mode)

;; Add auto modes
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
(add-to-list 'auto-mode-alist '("Makefrag\\'" . makefile-gmake-mode))
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

(add-hook 'python-mode-hoo 'my-py-indent-setup)
(add-hook 'c-mode-hook 'my-c-indent-setup)
(add-hook 'c++-mode-hook 'my-c-indent-setup)

(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

(add-hook 'html-mode-hook
		  (setq tab-width 3))

(put 'narrow-to-region 'disabled nil)

(setq tex-mode-hook '(lambda () (auto-fill-mode 1)))
(setq latex-mode-hook '(lambda () (auto-fill-mode 1)))
(setq org-mode-hook '(lambda () (auto-fill-mode 1)))

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
