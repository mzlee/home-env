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
(setq line-number-mode t)
(setq column-number-mode t)

;; Add installed modules
(add-to-list 'load-path "~/.emacs.d/site-lisp")
(add-to-list 'load-path "/usr/share/emacs/site-lisp")
(add-to-list 'load-path "/usr/local/share/emacs/site-lisp")

(require 'org-install)
(require 'yaml-mode)
(require 'matlab-mode)
(require 'org-velocity)
(require 'tramp)
;; (require 'tuareg)
;; (require 'tblgen)
;; (require 'camldebug)

;; Add modes
(setq org-velocity-bucket (expand-file-name "bucket.org" org-directory))
(global-set-key (kbd "C-c v") 'org-velocity-read)

(autoload 'markdown-mode "markdown-mode"
   "Major mode for editing Markdown files" t)

;; Add auto modes
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
(add-to-list 'auto-mode-alist '("Makefrag\\." . makefile-gmake-mode))
(add-to-list 'auto-mode-alist '("Makefile\\." . makefile-gmake-mode))
(add-to-list 'auto-mode-alist '("emacs\\'" . emacs-lisp-mode))
(add-to-list 'auto-mode-alist '("bash" . shell-script-mode))
;; (add-to-list 'auto-mode-alist '("\\.ml\\w?" . tuareg-mode))
(add-to-list 'auto-mode-alist '("\\.td" . tblgen-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

;; (autoload 'tuareg-mode "tuareg" "Major mode for editing Caml code" t)
;; (autoload 'camldebug "camldebug" "Run the Caml debugger" t)
;; (autoload 'tblgen-mode "tblgen" "Major mode for editing TableGen code" t)

;; Org Mode keys
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

(global-font-lock-mode 1)                     ; for all buffers
(add-hook 'org-mode-hook 'turn-on-font-lock)  ; Org buffers only

(setq c-basic-offset 4)
(setq python-basic-offset 4)

(global-set-key [?\M-1] 'goto-line)
(global-set-key [?\M-5] 'query-replace-regexp)
(global-set-key "\C-x/" 'comment-or-uncomment-region)

(defun c-lineup-arglist-tabs-only (ignored)
  "Line up argument lists by tabs, not spaces"
  (let* ((anchor (c-langelem-pos c-syntactic-element))
	 (column (c-langelem-2nd-pos c-syntactic-element))
	 (offset (- (1+ column) anchor))
	 (steps (floor offset c-basic-offset)))
    (* (max steps 1)
       c-basic-offset)))

(defun c-user-code-indent-setup ()
  (setq indent-tabs-mode nil)
  (setq c-basic-offset 4))

(defun c-tab-code-indent-setup ()
  (setq indent-tabs-mode t)
  (setq default-tab-width 4)
  (setq c-basic-offset 4))

(defun c-nginx-code-indent-setup ()
  (setq indent-tabs-mode nil)
  (setq vc-handled-backends nil)
  (setq c-basic-offset 4))

(defun c-qemu-code-indent-setup ()
  (setq indent-tabs-mode nil)
  (setq vc-handled-backends nil)
  (setq c-basic-offset 4))

(defun c-qt-code-indent-setup ()
  (setq indent-tabs-mode nil)
  (setq vc-handled-backends nil)
  (setq c-basic-offset 4))

(defun c-kernel-code-indent-setup ()
  (setq indent-tabs-mode t)
  (setq tab-width 4)
  (setq vc-handled-backends nil)
  (c-set-style "linux-tabs-only"))

(defun java-code-indent-setup ()
  (setq indent-tabs-mode nil)
  (setq c-basic-offset 4))

(defun my-py-indent-setup ()
  (setq indent-tabs-mode nil)
  (setq python-basic-offset 4))

(defun my-org-indent-setup ()
  (auto-fill-mode 1)
  (setq indent-tabs-mode nil))

(add-hook 'c-mode-common-hook
          (lambda ()
            (c-add-style
             "linux-tabs-only"
             '("linux" (c-offsets-alist
                        (arglist-cont-nonempty
                         c-lineup-gcc-asm-reg
                         c-lineup-arglist-tabs-only))))))

(add-hook 'c-mode-hook
	  (lambda ()
            (let ((filename (buffer-file-name)))
              ;; Enable kernel mode for the appropriate files
              (when (and filename
			 (or (string-match "/linux.*/" filename)
			     (string-match "/kern.*/" filename)))
		(c-kernel-code-indent-setup)))))

(add-hook 'c-mode-hook
	  (lambda ()
            (let ((filename (buffer-file-name)))
              ;; Enable relic mode for the appropreiate files
              (when (and filename
			 (string-match "/relic.*/" filename))
		(c-tab-code-indent-setup)))))
(add-hook 'c-mode-hook
	  (lambda ()
            (let ((filename (buffer-file-name)))
              ;; Enable qemu mode for the appropriate files
              (when (and filename
			 (string-match "/qemu.*/" filename))
		(c-qemu-code-indent-setup))
              (when (and filename
			 (string-match "/nginx.*/" filename))
		(c-nginx-code-indent-setup))
              (when (and filename
			 (string-match "/qt.*/" filename))
		(c-qt-code-indent-setup))
	      )))
;; (add-hook 'c-mode-hook
;; 	  (lambda ()
;;             (let ((filename (buffer-file-name)))
;;               ;; Enable kernel mode for the appropriate files
;;               (when (and filename
;; 			 (string-match "/nginx.*/" filename ))
;; 		(c-nginx-code-indent-setup)))))
;; (add-hook 'c-mode-hook
;; 	  (lambda ()
;;             (let ((filename (buffer-file-name)))
;;               ;; Enable kernel mode for the appropriate files
;;               (when (and filename
;; 			 (string-match "/qt.*/" filename ))
;; 		(c-qt-code-indent-setup)))))
(add-hook 'c-mode-hook 'c-user-code-indent-setup)
(add-hook 'c++-mode-hook 'c-user-code-indent-setup)
(add-hook 'java-mode-hook 'java-code-indent-setup)
(add-hook 'python-mode-hook 'my-py-indent-setup)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
(add-hook 'html-mode-hook (setq tab-width 4))
(add-hook 'tex-mode-hook (auto-fill-mode 1))
(add-hook 'latex-mode-hook (auto-fill-mode 1))
(add-hook 'org-mode-hook 'my-org-indent-setup)

(put 'narrow-to-region 'disabled nil)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(gud-gdb-command-name "gdb --annotate=1")
 '(large-file-warning-threshold nil)
 '(markdown-command "markdown_py")
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
