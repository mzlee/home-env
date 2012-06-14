;;; tblgen.el --- Caml mode for (X)Emacs.   -*- coding: latin-1 -*-
   
;;        Copyright © by INRIA, Albert Cohen, 2010.
;;        Licensed under the GNU General Public License.
;;
;;    This program is free software; you can redistribute it and/or modify
;;    it under the terms of the GNU General Public License as published by
;;    the Free Software Foundation; either version 2 of the License, or
;;    (at your option) any later version.
;;
;;    This program is distributed in the hope that it will be useful,
;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;    GNU General Public License for more details.

;;; Commentary:

;;; Code:

(require 'cl)
(require 'easymenu)

(defconst tblgen-mode-version "Tblgen Version 1.45.7"
  "        Copyright © by INRIA, Albert Cohen, 2010.
         Copying is covered by the GNU General Public License.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      Compatibility functions

(defalias 'tblgen-match-string
  (if (fboundp 'match-string-no-properties)
      'match-string-no-properties
    'match-string))

(if (not (fboundp 'read-shell-command))
    (defun read-shell-command  (prompt &optional initial-input history)
      "Read a string from the minibuffer, using `shell-command-history'."
      (read-from-minibuffer prompt initial-input nil nil
			    (or history 'shell-command-history))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             Import types and help features

(defvar tblgen-with-caml-mode-p
  (condition-case nil
      (and (require 'caml-types) (require 'caml-help))
    (error nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                       User customizable variables

;; Use the standard `customize' interface or `tblgen-mode-hook' to
;; Configure these variables

(require 'custom)

(defgroup tblgen nil
  "Support for the Objective Caml language."
  :group 'languages)

;; Comments

(defcustom tblgen-indent-leading-comments t
  "*If true, indent leading comment lines (starting with `(*') like others."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-indent-comments t
  "*If true, automatically align multi-line comments."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-comment-end-extra-indent 0
  "*How many spaces to indent a leading comment end `*)'.
If you expect comments to be indented like
	(*
          ...
	 *)
even without leading `*', use `tblgen-comment-end-extra-indent' = 1."
  :group 'tblgen
  :type '(radio :extra-offset 8
		:format "%{Comment End Extra Indent%}:
   Comment alignment:\n%v"
		(const :tag "align with `(' in comment opening" 0)
		(const :tag "align with `*' in comment opening" 1)
		(integer :tag "custom alignment" 0)))

(defcustom tblgen-support-leading-star-comments t
  "*Enable automatic intentation of comments of the form
        (*
         * ...
         *)
Documentation comments (** *) are not concerned by this variable
unless `tblgen-leading-star-in-doc' is also set.

If you do not set this variable and still expect comments to be
indented like
	(*
          ...
	 *)
\(without leading `*'), set `tblgen-comment-end-extra-indent' to 1."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-leading-star-in-doc nil
  "*Enable automatic intentation of documentation comments of the form
        (**
         * ...
         *)"
  :group 'tblgen :type 'boolean)

;; Indentation defaults

(defcustom tblgen-default-indent 2
  "*Default indentation.

Global indentation variable (large values may lead to indentation overflows).
When no governing keyword is found, this value is used to indent the line
if it has to."
  :group 'tblgen :type 'integer)

(defcustom tblgen-lazy-paren nil
  "*If true, indent parentheses like a standard keyword."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-support-camllight nil
  "*If true, handle Caml Light character syntax (incompatible with labels)."
  :group 'tblgen :type 'boolean
  :set '(lambda (var val)
	  (setq tblgen-support-camllight val)
	  (if (boundp 'tblgen-mode-syntax-table)
	      (modify-syntax-entry ?` (if val "\"" ".")
				   tblgen-mode-syntax-table))))

(defcustom tblgen-support-metaocaml nil
  "*If true, handle MetaOCaml character syntax."
  :group 'tblgen :type 'boolean
  :set '(lambda (var val)
	  (setq tblgen-support-metaocaml val)
	  (if (boundp 'tblgen-font-lock-keywords)
	      (tblgen-install-font-lock))))

(defcustom tblgen-let-always-indent t
  "*If true, enforce indentation is at least `tblgen-let-indent' after a `let'.

As an example, set it to false when you have `tblgen-with-indent' set to 0,
and you want `let x = match ... with' and `match ... with' indent the
same way."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-|-extra-unindent tblgen-default-indent
  "*Extra backward indent for Caml lines starting with the `|' operator.

It is NOT the variable controlling the indentation of the `|' itself:
this value is automatically added to `function', `with', `parse' and
some cases of `type' keywords to leave enough space for `|' backward
indentation.

For exemple, setting this variable to 0 leads to the following indentation:
  match ... with
    X -> ...
    | Y -> ...
    | Z -> ...

To modify the indentation of lines lead by `|' you need to modify the
indentation variables for `with', `function' and `parse', and possibly
for `type' as well. For example, setting them to 0 (and leaving
`tblgen-|-extra-unindent' to its default value) yields:
  match ... with
    X -> ...
  | Y -> ...
  | Z -> ..."
  :group 'tblgen :type 'integer)

(defcustom tblgen-class-indent tblgen-default-indent
  "*How many spaces to indent from a `class' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-sig-struct-align t
  "*Align `sig' and `struct' keywords with `module'."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-sig-struct-indent tblgen-default-indent
  "*How many spaces to indent from a `sig' or `struct' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-method-indent tblgen-default-indent
  "*How many spaces to indent from a `method' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-begin-indent tblgen-default-indent
  "*How many spaces to indent from a `begin' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-for-while-indent tblgen-default-indent
  "*How many spaces to indent from a `for' or `while' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-do-indent tblgen-default-indent
  "*How many spaces to indent from a `do' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-fun-indent tblgen-default-indent
  "*How many spaces to indent from a `fun' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-function-indent tblgen-default-indent
  "*How many spaces to indent from a `function' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-if-then-else-indent tblgen-default-indent
  "*How many spaces to indent from an `if', `then' or `else' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-let-indent tblgen-default-indent
  "*How many spaces to indent from a `let' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-in-indent tblgen-default-indent
  "*How many spaces to indent from a `in' keyword.
A lot of people like formatting `let' ... `in' expressions whithout
indentation:
        let x = 0 in
        blah x
Set this variable to 0 to get this behaviour.
However, nested declarations are always correctly handled:
        let x = 0 in                             let x = 0
        let y = 0 in              or             in let y = 0
        let z = 0 ...                            in let z = 0 ..."
  :group 'tblgen :type 'integer)

(defcustom tblgen-match-indent tblgen-default-indent
  "*How many spaces to indent from a `match' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-try-indent tblgen-default-indent
  "*How many spaces to indent from a `try' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-with-indent tblgen-default-indent
  "*How many spaces to indent from a `with' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-rule-indent tblgen-default-indent
  "*How many spaces to indent from a `rule' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-parse-indent tblgen-default-indent
  "*How many spaces to indent from a `parse' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-parser-indent tblgen-default-indent
  "*How many spaces to indent from a `parser' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-type-indent tblgen-default-indent
  "*How many spaces to indent from a `type' keyword."
  :group 'tblgen :type 'integer)

(defcustom tblgen-val-indent tblgen-default-indent
  "*How many spaces to indent from a `val' keyword."
  :group 'tblgen :type 'integer)

;; Automatic indentation
;; Using abbrev-mode and electric keys

(defcustom tblgen-use-abbrev-mode t
  "*Non-nil means electrically indent lines starting with leading keywords.
Leading keywords are such as `end', `done', `else' etc.
It makes use of `abbrev-mode'.

Many people find eletric keywords irritating, so you can disable them by
setting this variable to nil."
  :group 'tblgen :type 'boolean
  :set '(lambda (var val)
	  (setq tblgen-use-abbrev-mode val)
	  (abbrev-mode val)))

(defcustom tblgen-electric-indent t
  "*Non-nil means electrically indent lines starting with `|', `)', `]' or `}'.

Many people find eletric keys irritating, so you can disable them in
setting this variable to nil."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-electric-close-vector t
  "*Non-nil means electrically insert `|' before a vector-closing `]' or
`>' before an object-closing `}'.

Many people find eletric keys irritating, so you can disable them in
setting this variable to nil. You should probably have this on,
though, if you also have `tblgen-electric-indent' on."
  :group 'tblgen :type 'boolean)

;; Tblgen-Interactive
;; Configure via `tblgen-mode-hook'

(defcustom tblgen-skip-after-eval-phrase t
  "*Non-nil means skip to the end of the phrase after evaluation in the
Caml toplevel."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-interactive-read-only-input nil
  "*Non-nil means input sent to the Caml toplevel is read-only."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-interactive-echo-phrase t
  "*Non-nil means echo phrases in the toplevel buffer when sending
them to the Caml toplevel."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-interactive-input-font-lock t
  "*Non nil means Font-Lock for toplevel input phrases."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-interactive-output-font-lock t
  "*Non nil means Font-Lock for toplevel output messages."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-interactive-error-font-lock t
  "*Non nil means Font-Lock for toplevel error messages."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-display-buffer-on-eval t
  "*Non nil means pop up the Caml toplevel when evaluating code."
  :group 'tblgen :type 'boolean)

(defcustom tblgen-manual-url "http://pauillac.inria.fr/ocaml/htmlman/index.html"
  "*URL to the Caml reference manual."
  :group 'tblgen :type 'string)

(defcustom tblgen-browser 'tblgen-netscape-manual
  "*Name of function that displays the Caml reference manual.
Valid names are `tblgen-netscape-manual', `tblgen-mmm-manual'
and `tblgen-xemacs-w3-manual' (XEmacs only)."
  :group 'tblgen)

(defcustom tblgen-library-path "/usr/local/lib/ocaml/"
  "*Path to the Caml library."
  :group 'tblgen :type 'string)

(defcustom tblgen-definitions-max-items 30
  "*Maximum number of items a definitions menu can contain."
  :group 'tblgen :type 'integer)

(defvar tblgen-options-list
  '(("Lazy parentheses indentation" . 'tblgen-lazy-paren)
    ("Force indentation after `let'" . 'tblgen-let-always-indent)
    "---"
    ("Automatic indentation of leading keywords" . 'tblgen-use-abbrev-mode)
    ("Electric indentation of ), ] and }" . 'tblgen-electric-indent)
    ("Electric matching of [| and {<" . 'tblgen-electric-close-vector)
    "---"
    ("Indent body of comments" . 'tblgen-indent-comments)
    ("Indent first line of comments" . 'tblgen-indent-leading-comments)
    ("Leading-`*' comment style" . 'tblgen-support-leading-star-comments))
  "*List of menu-configurable Tblgen options.")

(defvar tblgen-interactive-options-list
  '(("Skip phrase after evaluation" . 'tblgen-skip-after-eval-phrase)
    ("Echo phrase in interactive buffer" . 'tblgen-interactive-echo-phrase)
    "---"
    ("Font-lock interactive input" . 'tblgen-interactive-input-font-lock)
    ("Font-lock interactive output" . 'tblgen-interactive-output-font-lock)
    ("Font-lock interactive error" . 'tblgen-interactive-error-font-lock)
    "---"
    ("Read only input" . 'tblgen-interactive-read-only-input))
  "*List of menu-configurable Tblgen options.")

(defvar tblgen-interactive-program "ocaml"
  "*Default program name for invoking a Caml toplevel from Emacs.")
;; Could be interesting to have this variable buffer-local
;;   (e.g., ocaml vs. metaocaml buffers)
;; (make-variable-buffer-local 'tblgen-interactive-program)

;; Backtrack to custom parsing and caching by default, until stable
;;(defvar tblgen-use-syntax-ppss (fboundp 'syntax-ppss)
(defconst tblgen-use-syntax-ppss nil
  "*If nil, use our own parsing and caching.")

(defgroup tblgen-faces nil
  "Special faces for the Tblgen mode."
  :group 'tblgen)

(defconst tblgen-faces-inherit-p
  (if (boundp 'face-attribute-name-alist)
      (assq :inherit face-attribute-name-alist)))

(defface tblgen-font-lock-governing-face
  (if tblgen-faces-inherit-p
      '((t :inherit font-lock-keyword-face))
    '((((background light)) (:foreground "darkorange3" :bold t))
      (t (:foreground "orange" :bold t))))
  "Face description for governing/leading keywords."
  :group 'tblgen-faces)
(defvar tblgen-font-lock-governing-face
  'tblgen-font-lock-governing-face)

(defface tblgen-font-lock-multistage-face
  '((((background light))
     (:foreground "darkblue" :background "lightgray" :bold t))
    (t (:foreground "steelblue" :background "darkgray" :bold t)))
  "Face description for MetaOCaml staging operators."
  :group 'tblgen-faces)
(defvar tblgen-font-lock-multistage-face
  'tblgen-font-lock-multistage-face)

(defface tblgen-font-lock-operator-face
  (if tblgen-faces-inherit-p
      '((t :inherit font-lock-keyword-face))
    '((((background light)) (:foreground "brown"))
      (t (:foreground "khaki"))))
  "Face description for all operators."
  :group 'tblgen-faces)
(defvar tblgen-font-lock-operator-face
  'tblgen-font-lock-operator-face)

(defface tblgen-font-lock-error-face
  '((t (:foreground "yellow" :background "red" :bold t)))
  "Face description for all errors reported to the source."
  :group 'tblgen-faces)
(defvar tblgen-font-lock-error-face
  'tblgen-font-lock-error-face)

(defface tblgen-font-lock-interactive-output-face
  '((((background light))
     (:foreground "blue4"))
    (t (:foreground "cyan")))
  "Face description for all toplevel outputs."
  :group 'tblgen-faces)
(defvar tblgen-font-lock-interactive-output-face
  'tblgen-font-lock-interactive-output-face)

(defface tblgen-font-lock-interactive-error-face
  (if tblgen-faces-inherit-p
      '((t :inherit font-lock-warning-face))
    '((((background light)) (:foreground "red3"))
      (t (:foreground "red2"))))
  "Face description for all toplevel errors."
  :group 'tblgen-faces)
(defvar tblgen-font-lock-interactive-error-face
  'tblgen-font-lock-interactive-error-face)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            Support definitions

(defun tblgen-leading-star-p ()
  (and tblgen-support-leading-star-comments
       (save-excursion ; this function does not make sense outside of a comment
	 (tblgen-beginning-of-literal-or-comment)
	 (and (or tblgen-leading-star-in-doc
		  (not (looking-at "(\\*[Tt][Ee][Xx]\\|(\\*\\*")))
	      (progn
		(forward-line 1)
		(back-to-indentation)
		(looking-at "\\*[^)]"))))))

(defun tblgen-auto-fill-insert-leading-star (&optional leading-star)
  (let ((point-leading-comment (looking-at "(\\*")) (return-leading nil))
    (save-excursion
      (back-to-indentation)
      (if tblgen-electric-indent
	  (progn
	    (if (and (tblgen-in-comment-p)
		     (or leading-star
			 (tblgen-leading-star-p)))
		(progn
		  (if (not (looking-at "(?\\*"))
		      (insert-before-markers "* "))
		  (setq return-leading t)))
	    (if (not point-leading-comment)
		;; Use optional argument to break recursion
		(tblgen-indent-command t)))))
    return-leading))

(defun tblgen-auto-fill-function ()
  (if (tblgen-in-literal-p) ()
    (let ((leading-star
	   (if (not (char-equal ?\n last-command-char))
	       (tblgen-auto-fill-insert-leading-star)
	     nil)))
      (do-auto-fill)
      (if (not (char-equal ?\n last-command-char))
	  (tblgen-auto-fill-insert-leading-star leading-star)))))

(defun tblgen-forward-char (&optional step)
  (if step (goto-char (+ (point) step))
    (goto-char (1+ (point)))))

(defun tblgen-backward-char (&optional step)
  (if step (goto-char (- (point) step))
    (goto-char (1- (point)))))

(defun tblgen-in-indentation-p ()
  "Return non-nil if all chars between beginning of line and point are blanks."
  (save-excursion
    (skip-chars-backward " \t")
    (bolp)))

(defvar tblgen-cache-stop (point-min))
(make-variable-buffer-local 'tblgen-cache-stop)
(defvar tblgen-cache nil)
(make-variable-buffer-local 'tblgen-cache)
(defvar tblgen-cache-local nil)
(make-variable-buffer-local 'tblgen-cache-local)
(defvar tblgen-cache-last-local nil)
(make-variable-buffer-local 'tblgen-cache-last-local)
(defvar tblgen-last-loc (cons nil nil))
  
(if tblgen-use-syntax-ppss
    (progn
      (defun tblgen-in-literal-p ()
	"Returns non-nil if point is inside a Caml literal."
	(nth 3 (syntax-ppss)))
      (defun tblgen-in-comment-p ()
	"Returns non-nil if point is inside a Caml comment."
	(nth 4 (syntax-ppss)))
      (defun tblgen-in-literal-or-comment-p ()
	"Returns non-nil if point is inside a Caml literal or comment."
	(nth 8 (syntax-ppss)))
      (defun tblgen-beginning-of-literal-or-comment ()
	"Skips to the beginning of the current literal or comment (or buffer)."
	(interactive)
	(goto-char (or (nth 8 (syntax-ppss)) (point))))
      (defun tblgen-beginning-of-literal-or-comment-fast ()
	(goto-char (or (nth 8 (syntax-ppss)) (point-min))))
      ;; FIXME: not clear if moving out of a string/comment counts as 1 or no.
      (defalias 'tblgen-backward-up-list 'backward-up-list))

  (defun tblgen-before-change-function (begin end)
    (setq tblgen-cache-stop
	  (if (save-excursion (beginning-of-line) (= (point) (point-min)))
	      (point-min)
	    (min tblgen-cache-stop (1- begin)))))
  
  (defun tblgen-in-literal-p ()
    "Return non-nil if point is inside a Caml literal."
    (car (tblgen-in-literal-or-comment)))
  (defun tblgen-in-comment-p ()
    "Return non-nil if point is inside a Caml comment."
    (cdr (tblgen-in-literal-or-comment)))
  (defun tblgen-in-literal-or-comment-p ()
    "Return non-nil if point is inside a Caml literal or comment."
    (tblgen-in-literal-or-comment)
    (or (car tblgen-last-loc) (cdr tblgen-last-loc)))
  (defun tblgen-in-literal-or-comment ()
    "Return the pair `((tblgen-in-literal-p) . (tblgen-in-comment-p))'."
    (if (and (<= (point) tblgen-cache-stop) tblgen-cache)
	(progn
	  (if (or (not tblgen-cache-local) (not tblgen-cache-last-local)
		  (and (>= (point) (caar tblgen-cache-last-local))))
	      (setq tblgen-cache-local tblgen-cache))
	  (while (and tblgen-cache-local (< (point) (caar tblgen-cache-local)))
	    (setq tblgen-cache-last-local tblgen-cache-local
		  tblgen-cache-local (cdr tblgen-cache-local)))
	  (setq tblgen-last-loc
		(if tblgen-cache-local
		    (cons (eq (cadar tblgen-cache-local) 'b)
			  (> (cddar tblgen-cache-local) 0))
		  (cons nil nil))))
      (let ((flag t) (op (point)) (mp (min (point) (1- (point-max))))
	    (balance 0) (end-of-comment nil))
	(while (and tblgen-cache (<= tblgen-cache-stop (caar tblgen-cache)))
	  (setq tblgen-cache (cdr tblgen-cache)))
	(if tblgen-cache
	    (if (eq (cadar tblgen-cache) 'b)
		(progn
		  (setq tblgen-cache-stop (1- (caar tblgen-cache)))
		  (goto-char tblgen-cache-stop)
		  (setq balance (cddar tblgen-cache))
		  (setq tblgen-cache (cdr tblgen-cache)))
	      (setq balance (cddar tblgen-cache))
	      (setq tblgen-cache-stop (caar tblgen-cache))
	      (goto-char tblgen-cache-stop)
	      (skip-chars-forward "("))
	  (goto-char (point-min)))
	(skip-chars-backward "\\\\*")
	(while flag
	  (if end-of-comment (setq balance 0 end-of-comment nil))
	  (skip-chars-forward "^\\\\'`\"(\\*")
	  (cond
	   ((looking-at "\\\\")
	    (tblgen-forward-char 2))
	   ((looking-at "'\\([^\n\\']\\|\\\\[^ \t\n][^ \t\n]?[^ \t\n]?\\)'")
	    (setq tblgen-cache (cons (cons (1+ (point)) (cons 'b balance))
				     tblgen-cache))
	    (goto-char (match-end 0))
	    (setq tblgen-cache (cons (cons (point) (cons 'e balance))
				     tblgen-cache)))
	   ((and
	     tblgen-support-camllight
	     (looking-at "`\\([^\n\\']\\|\\\\[^ \t\n][^ \t\n]?[^ \t\n]?\\)`"))
	    (setq tblgen-cache (cons (cons (1+ (point)) (cons 'b balance))
				     tblgen-cache))
	    (goto-char (match-end 0))
	    (setq tblgen-cache (cons (cons (point) (cons 'e balance))
				     tblgen-cache)))
	   ((looking-at "\"")
	    (tblgen-forward-char)
	    (setq tblgen-cache (cons (cons (point) (cons 'b balance))
				     tblgen-cache))
	    (skip-chars-forward "^\\\\\"")
	    (while (looking-at "\\\\")
	      (tblgen-forward-char 2) (skip-chars-forward "^\\\\\""))
	    (tblgen-forward-char)
	    (setq tblgen-cache (cons (cons (point) (cons 'e balance))
				     tblgen-cache)))
	   ((looking-at "(\\*")
	    (setq balance (1+ balance))
	    (setq tblgen-cache (cons (cons (point) (cons nil balance))
				     tblgen-cache))
	    (tblgen-forward-char 2))
	   ((looking-at "\\*)")
	    (tblgen-forward-char 2)
	    (if (> balance 1)
		(progn
		  (setq balance (1- balance))
		  (setq tblgen-cache (cons (cons (point) (cons nil balance))
					   tblgen-cache)))
	      (setq end-of-comment t)
	      (setq tblgen-cache (cons (cons (point) (cons nil 0))
				       tblgen-cache))))
	   (t (tblgen-forward-char)))
	  (setq flag (<= (point) mp)))
	(setq tblgen-cache-local tblgen-cache
	      tblgen-cache-stop (point))
	(goto-char op)
	(if tblgen-cache (tblgen-in-literal-or-comment) 
	  (setq tblgen-last-loc (cons nil nil))
	  tblgen-last-loc))))
  
  (defun tblgen-beginning-of-literal-or-comment ()
    "Skips to the beginning of the current literal or comment (or buffer)."
    (interactive)
    (if (tblgen-in-literal-or-comment-p)
	(tblgen-beginning-of-literal-or-comment-fast)))
  
  (defun tblgen-beginning-of-literal-or-comment-fast ()
    (while (and tblgen-cache-local
		(or (eq 'b (cadar tblgen-cache-local))
		    (> (cddar tblgen-cache-local) 0)))
      (setq tblgen-cache-last-local tblgen-cache-local
	    tblgen-cache-local (cdr tblgen-cache-local)))
    (if tblgen-cache-last-local
	(goto-char (caar tblgen-cache-last-local))
      (goto-char (point-min)))
    (if (eq 'b (cadar tblgen-cache-last-local)) (tblgen-backward-char)))
  
  (defun tblgen-backward-up-list ()
    "Safe up-list regarding comments, literals and errors."
    (let ((balance 1) (op (point)) (oc nil))
      (tblgen-in-literal-or-comment)
      (while (and (> (point) (point-min)) (> balance 0))
	(setq oc (if tblgen-cache-local (caar tblgen-cache-local) (point-min)))
	(condition-case nil (up-list -1) (error (goto-char (point-min))))
	(if (>= (point) oc) (setq balance (1- balance))
	  (goto-char op)
	  (skip-chars-backward "^[]{}()") (tblgen-backward-char)
	  (if (not (tblgen-in-literal-or-comment-p))
	      (cond
	       ((looking-at "[[{(]")
		(setq balance (1- balance)))
	       ((looking-at "[]})]")
		(setq balance (1+ balance))))
	    (tblgen-beginning-of-literal-or-comment-fast)))
	(setq op (point)))))) ;; End of (if tblgen-use-syntax-ppss

(defun tblgen-false-=-p ()
  "Is the underlying `=' the first/second letter of an operator?"
  (or (memq (preceding-char) '(?: ?> ?< ?=))
      (char-equal ?= (char-after (1+ (point))))))

(defun tblgen-at-phrase-break-p ()
  "Is the underlying `;' a phrase break?"
  (and (char-equal ?\; (following-char))
       (or (and (not (eobp))
		(char-equal ?\; (char-after (1+ (point)))))
	   (char-equal ?\; (preceding-char)))))

(defun tblgen-assoc-indent (kwop &optional look-for-let-or-and)
  "Return relative indentation of the keyword given in argument."
  (let ((ind (symbol-value (cdr (assoc kwop tblgen-keyword-alist))))
	(looking-let-or-and (and look-for-let-or-and
				 (looking-at "\\<\\(let\\|and\\)\\>"))))
    (if (string-match "\\<\\(with\\|function\\|parser?\\)\\>" kwop)
	(+ (if (and tblgen-let-always-indent
		    looking-let-or-and (< ind tblgen-let-indent))
	       tblgen-let-indent ind)
	   tblgen-|-extra-unindent)
      ind)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                           Sym-lock in Emacs

;; By Stefan Monnier

(defcustom tblgen-font-lock-symbols nil
  "Display fun and -> and such using symbols in fonts.
This may sound like a neat trick, but note that it can change the
alignment and can thus lead to surprises."
  :type 'bool)

(defvar tblgen-font-lock-symbols-alist
  (append
   ;; The symbols can come from a JIS0208 font.
   (and (fboundp 'make-char) (fboundp 'charsetp) (charsetp 'japanese-jisx0208)
	(list (cons "fun" (make-char 'japanese-jisx0208 38 75))
	      (cons "sqrt" (make-char 'japanese-jisx0208 34 101))
	      (cons "not" (make-char 'japanese-jisx0208 34 76))
	      (cons "or" (make-char 'japanese-jisx0208 34 75))
	      (cons "||" (make-char 'japanese-jisx0208 34 75))
	      (cons "&&" (make-char 'japanese-jisx0208 34 74))
	      ;; (cons "*." (make-char 'japanese-jisx0208 33 95))
	      ;; (cons "/." (make-char 'japanese-jisx0208 33 96))
	      (cons "->" (make-char 'japanese-jisx0208 34 42))
	      (cons "=>" (make-char 'japanese-jisx0208 34 77))
	      (cons "<-" (make-char 'japanese-jisx0208 34 43))
	      (cons "<>" (make-char 'japanese-jisx0208 33 98))
	      (cons "==" (make-char 'japanese-jisx0208 34 97))
	      (cons ">=" (make-char 'japanese-jisx0208 33 102))
	      (cons "<=" (make-char 'japanese-jisx0208 33 101))
	      ;; Some greek letters for type parameters.
	      (cons "'a" (make-char 'japanese-jisx0208 38 65))
	      (cons "'b" (make-char 'japanese-jisx0208 38 66))
	      (cons "'c" (make-char 'japanese-jisx0208 38 67))
	      (cons "'d" (make-char 'japanese-jisx0208 38 68))))
   ;; Or a unicode font.
   (and (fboundp 'decode-char)
	(list (cons "fun" (decode-char 'ucs 955))
	      (cons "sqrt" (decode-char 'ucs 8730))
	      (cons "not" (decode-char 'ucs 172))
	      (cons "or" (decode-char 'ucs 8897))
	      (cons "&&" (decode-char 'ucs 8896))
	      (cons "||" (decode-char 'ucs 8897))
	      ;; (cons "*." (decode-char 'ucs 215))
	      ;; (cons "/." (decode-char 'ucs 247))
	      (cons "->" (decode-char 'ucs 8594))
	      (cons "<-" (decode-char 'ucs 8592))
	      (cons "<=" (decode-char 'ucs 8804))
	      (cons ">=" (decode-char 'ucs 8805))
	      (cons "<>" (decode-char 'ucs 8800))
	      (cons "==" (decode-char 'ucs 8801))
	      ;; Some greek letters for type parameters.
	      (cons "'a" (decode-char 'ucs 945))
	      (cons "'b" (decode-char 'ucs 946))
	      (cons "'c" (decode-char 'ucs 947))
	      (cons "'d" (decode-char 'ucs 948))
	      ))))

(defun tblgen-font-lock-compose-symbol (alist)
  "Compose a sequence of ascii chars into a symbol.
Regexp match data 0 points to the chars."
  ;; Check that the chars should really be composed into a symbol.
  (let* ((start (match-beginning 0))
	 (end (match-end 0))
	 (syntaxes (if (eq (char-syntax (char-after start)) ?w)
		       '(?w) '(?. ?\\))))
    (if (or (memq (char-syntax (or (char-before start) ?\ )) syntaxes)
	    (memq (char-syntax (or (char-after end) ?\ )) syntaxes)
	    (memq (get-text-property start 'face)
		  '(tblgen-doc-face font-lock-string-face
		    font-lock-comment-face)))
	;; No composition for you. Let's actually remove any composition
	;; we may have added earlier and which is now incorrect.
	(remove-text-properties start end '(composition))
      ;; That's a symbol alright, so add the composition.
      (compose-region start end (cdr (assoc (match-string 0) alist)))))
  ;; Return nil because we're not adding any face property.
  nil)

(defun tblgen-font-lock-symbols-keywords ()
  (when (fboundp 'compose-region)
    (let ((alist nil))
      (dolist (x tblgen-font-lock-symbols-alist)
	(when (and (if (fboundp 'char-displayable-p)
		       (char-displayable-p (cdr x))
		     t)
		   (not (assoc (car x) alist)))	;Not yet in alist.
	  (push x alist)))
      (when alist
	`((,(regexp-opt (mapcar 'car alist) t)
	   (0 (tblgen-font-lock-compose-symbol ',alist))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                  Font-Lock

(unless tblgen-use-syntax-ppss

(defun tblgen-fontify-buffer ()
  (font-lock-default-fontify-buffer)
  (tblgen-fontify (point-min) (point-max)))

(defun tblgen-fontify-region (begin end &optional verbose)
  (font-lock-default-fontify-region begin end verbose)
  (tblgen-fontify begin end))

(defun tblgen-fontify (begin end)
  (if (eq major-mode 'tblgen-mode)
      (save-excursion
	(let ((modified (buffer-modified-p))) ; Emacs hack (see below)
	  (goto-char begin)
	  (beginning-of-line)
	  (setq begin (point))
	  (goto-char (1- end))
	  (end-of-line)
	  ;; Dirty hack to trick `font-lock-default-unfontify-region'
	  (if (not tblgen-with-xemacs) (forward-line 2))
	  (setq end (point))
	  (while (> end begin)
	    (goto-char (1- end))
	    (tblgen-in-literal-or-comment)
	    (cond
	     ((cdr tblgen-last-loc)
	      (tblgen-beginning-of-literal-or-comment)
	      (put-text-property (max begin (point)) end 'face
				 (if (looking-at
				      "(\\*[Tt][Ee][Xx]\\|(\\*\\*[^*]")
				     tblgen-doc-face
				   'font-lock-comment-face))
	      (setq end (1- (point))))
	     ((car tblgen-last-loc)
	      (tblgen-beginning-of-literal-or-comment)
	      (put-text-property (max begin (point)) end 'face
				 'font-lock-string-face)
	      (setq end (point)))
	     (t (while (and tblgen-cache-local
			    (or (> (caar tblgen-cache-local) end)
				(eq 'b (cadar tblgen-cache-local))))
		  (setq tblgen-cache-local (cdr tblgen-cache-local)))
		(setq end (if tblgen-cache-local
			      (caar tblgen-cache-local) begin)))))
	  (if (not (or tblgen-with-xemacs modified)) ; properties taken
	      (set-buffer-modified-p nil))))))       ; too seriously...

;; XEmacs and Emacs have different documentation faces...
(defvar tblgen-doc-face (if (facep 'font-lock-doc-face)
			    'font-lock-doc-face
			  'font-lock-doc-string-face))

) ;; End of (unless tblgen-use-syntax-ppss
  
;; By Stefan Monnier: redesigned font-lock installation and use char classes

;; When char classes are not available, character ranges only span
;; ASCII characters for MULE compatibility
(defconst tblgen-use-char-classes (string-match "[[:alpha:]]" "x"))
(defconst tblgen-lower (if tblgen-use-char-classes "[:lower:]" "a-z"))
(defconst tblgen-alpha (if tblgen-use-char-classes "[:alpha:]" "a-zA-Z"))

(defconst tblgen-font-lock-syntactic-keywords
  ;; Char constants start with ' but ' can also appear in identifiers.
  ;; Beware not to match things like '*)hel' or '"hel' since the first '
  ;; might be inside a string or comment.
  '(("\\<\\('\\)\\([^'\\\n]\\|\\\\.[^\\'\n \")]*\\)\\('\\)"
     (1 '(7)) (3 '(7)))))

(defun tblgen-font-lock-syntactic-face-function (state)
  (if (nth 3 state) font-lock-string-face
    (let ((start (nth 8 state)))
      (if (and (> (point-max) (+ start 2))
	       (eq (char-after (+ start 2)) ?*)
	       (not (eq (char-after (+ start 3)) ?*)))
	  ;; This is a documentation comment
	  tblgen-doc-face
	font-lock-comment-face))))

(when (facep 'font-lock-reference-face)
  (defvar font-lock-constant-face)
  (if (facep 'font-lock-constant-face) ()
    (defvar font-lock-constant-face font-lock-reference-face)
    (copy-face font-lock-reference-face 'font-lock-constant-face)))
(when (facep 'font-lock-keyword-face)
  (defvar font-lock-preprocessor-face)
  (if (facep 'font-lock-preprocessor-face) ()
    (defvar font-lock-preprocessor-face font-lock-keyword-face)
    (copy-face font-lock-keyword-face 'font-lock-preprocessor-face)))

;; Initially empty, set in `tblgen-install-font-lock'
(defvar tblgen-font-lock-keywords
  ()
  "Font-Lock patterns for Tblgen mode.")

(when (featurep 'sym-lock)
  (make-face 'tblgen-font-lock-lambda-face
	     "Face description for fun keywords (lambda operator).")
  (set-face-parent 'tblgen-font-lock-lambda-face
		   font-lock-function-name-face)
  (set-face-font 'tblgen-font-lock-lambda-face
		 sym-lock-font-name)
  
  ;; To change this table, xfd -fn '-adobe-symbol-*--12-*' may be
  ;; used to determine the symbol character codes.
  (defvar tblgen-sym-lock-keywords
    '(("<-" 0 1 172 nil)
      ("->" 0 1 174 nil)
      ("<=" 0 1 163 nil)
      (">=" 0 1 179 nil)
      ("<>" 0 1 185 nil)
      ("==" 0 1 186 nil)
      ("||" 0 1 218 nil)
      ("&&" 0 1 217 nil)
      ("[^*]\\(\\*\\)\\." 1 8 180 nil)
      ("\\(/\\)\\." 1 3 184 nil)
      (";;" 0 1 191 nil)
      ("\\<sqrt\\>" 0 3 214 nil)
      ("\\<fun\\>" 0 3 108 tblgen-font-lock-lambda-face)
      ("\\<or\\>" 0 3 218 nil)
      ("\\<not\\>" 0 3 216 nil))
    "If non nil: Overrides default Sym-Lock patterns for Tblgen."))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                    Keymap

(defvar tblgen-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "|" 'tblgen-electric)
    (define-key map ")" 'tblgen-electric-rp)
    (define-key map "}" 'tblgen-electric-rc)
    (define-key map "]" 'tblgen-electric-rb)
    (define-key map "\M-q" 'tblgen-indent-phrase)
    (define-key map "\C-c\C-q" 'tblgen-indent-phrase)
    (define-key map "\M-\C-\\" 'indent-region)
    (define-key map "\C-c\C-a" 'tblgen-find-alternate-file)
    (define-key map "\C-c\C-c" 'compile)
    (define-key map "\C-xnd" 'tblgen-narrow-to-phrase)
    (define-key map "\M-\C-x" 'tblgen-eval-phrase)
    (define-key map "\C-x\C-e" 'tblgen-eval-phrase)
    (define-key map "\C-c\C-e" 'tblgen-eval-phrase)
    (define-key map "\C-c\C-r" 'tblgen-eval-region)
    (define-key map "\C-c\C-b" 'tblgen-eval-buffer)
    (define-key map "\C-c\C-s" 'tblgen-run-caml)
    (define-key map "\C-c\C-i" 'tblgen-interrupt-caml)
    (define-key map "\C-c\C-k" 'tblgen-kill-caml)
    (define-key map "\C-c\C-n" 'tblgen-next-phrase)
    (define-key map "\C-c\C-p" 'tblgen-previous-phrase)
    (define-key map [(control c) (home)] 'tblgen-move-inside-block-opening)
    (define-key map [(control c) (control down)] 'tblgen-next-phrase)
    (define-key map [(control c) (control up)] 'tblgen-previous-phrase)
    (define-key map [(meta control down)]  'tblgen-next-phrase)
    (define-key map [(meta control up)] 'tblgen-previous-phrase)
    (define-key map [(meta control h)] 'tblgen-mark-phrase)
    (define-key map "\C-c`" 'tblgen-interactive-next-error-source)
    (define-key map "\C-c?" 'tblgen-interactive-next-error-source)
    (define-key map "\C-c.c" 'tblgen-insert-class-form)
    (define-key map "\C-c.b" 'tblgen-insert-begin-form)
    (define-key map "\C-c.f" 'tblgen-insert-for-form)
    (define-key map "\C-c.w" 'tblgen-insert-while-form)
    (define-key map "\C-c.i" 'tblgen-insert-if-form)
    (define-key map "\C-c.l" 'tblgen-insert-let-form)
    (define-key map "\C-c.m" 'tblgen-insert-match-form)
    (define-key map "\C-c.t" 'tblgen-insert-try-form)
    (when tblgen-with-caml-mode-p
      ;; Trigger caml-types
      (define-key map [?\C-c ?\C-t] 'caml-types-show-type)
      ;; To prevent misbehavior in case of error during exploration.
      (define-key map [(control mouse-2)] 'caml-types-mouse-ignore)
      (define-key map [(control down-mouse-2)] 'caml-types-explore)
      ;; Trigger caml-help
      (define-key map [?\C-c ?i] 'ocaml-add-path)
      (define-key map [?\C-c ?\[] 'ocaml-open-module)
      (define-key map [?\C-c ?\]] 'ocaml-close-module)
      (define-key map [?\C-c ?h] 'caml-help)
      (define-key map [?\C-c ?\t] 'caml-complete))
    map)
  "Keymap used in Tblgen mode.")
  
(defvar tblgen-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?? ". p" st)
    (modify-syntax-entry ?~ ". p" st)
    (modify-syntax-entry ?: "." st)
    (modify-syntax-entry ?' "w" st)	; ' is part of words (for primes).
    (modify-syntax-entry
     ;; ` is punctuation or character delimiter (Caml Light compatibility).
     ?` (if tblgen-support-camllight "\"" ".") st)
    (modify-syntax-entry ?\" "\"" st)	; " is a string delimiter
    (modify-syntax-entry ?\\ "\\" st)
    (modify-syntax-entry ?*  ". 23" st)
    (condition-case nil
	(progn
	  (modify-syntax-entry ?\( "()1n" st)
	  (modify-syntax-entry ?\) ")(4n" st))
      (error		   ;XEmacs signals an error instead of ignoring `n'.
       (modify-syntax-entry ?\( "()1" st)
       (modify-syntax-entry ?\) ")(4" st)))
    st)
  "Syntax table in use in Tblgen mode buffers.")

(defconst tblgen-font-lock-syntax
  `((?_ . "w") (?` . ".")
    ,@(unless tblgen-use-syntax-ppss
	'((?\" . ".") (?\( . ".") (?\) . ".") (?* . "."))))
  "Syntax changes for Font-Lock.")

(defvar tblgen-mode-abbrev-table ()
  "Abbrev table used for Tblgen mode buffers.")
(defun tblgen-define-abbrev (keyword)
  (define-abbrev tblgen-mode-abbrev-table keyword keyword 'tblgen-abbrev-hook))
(if tblgen-mode-abbrev-table ()
  (setq tblgen-mode-abbrev-table (make-abbrev-table))
  (mapcar 'tblgen-define-abbrev
	  '("module" "class" "functor" "object" "type" "val" "inherit"
	    "include" "virtual" "constraint" "exception" "external" "open"
	    "method" "and" "initializer" "to" "downto" "do" "done" "else"
	    "begin" "end" "let" "in" "then" "with"))
  (setq abbrevs-changed nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                              The major mode

;;;###autoload (add-to-list 'auto-mode-alist '("\\.ml[ily]?\\'" . tblgen-mode))

;;;###autoload
(defun tblgen-mode ()
  "Major mode for editing Caml code.

Dedicated to Emacs and XEmacs, version 21 and higher. Provides
automatic indentation and compilation interface. Performs font/color
highlighting using Font-Lock. It is designed for Objective Caml but
handles Objective Labl and Caml Light as well.

Report bugs, remarks and questions to Albert.Cohen@prism.uvsq.fr.

The Font-Lock minor-mode is used according to your customization
options. Within XEmacs (non-MULE versions only) you may also want to
use Sym-Lock:

\(if (and (boundp 'window-system) window-system)
    (when (string-match \"XEmacs\" emacs-version)
       	(if (not (and (boundp 'mule-x-win-initted) mule-x-win-initted))
            (require 'sym-lock))
       	(require 'font-lock)))

You have better byte-compile tblgen.el (and sym-lock.el if you use it)
because symbol highlighting is very time consuming.

For customization purposes, you should use `tblgen-mode-hook'
\(run for every file) or `tblgen-load-hook' (run once) and not patch
the mode itself. You should add to your configuration file something like:
  (add-hook 'tblgen-mode-hook
            (lambda ()
               ... ; your customization code
            ))
For example you can change the indentation of some keywords, the
`electric' flags, Font-Lock colors... Every customizable variable is
documented, use `C-h-v' or look at the mode's source code.

A special case is Sym-Lock customization: You may set
`tblgen-sym-lock-keywords' in your `.emacs' configuration file
to override default Sym-Lock patterns.

`custom-tblgen.el' is a sample customization file for standard changes.
You can append it to your `.emacs' or use it as a tutorial.

`M-x camldebug' FILE starts the Caml debugger camldebug on the executable
FILE, with input and output in an Emacs buffer named *camldebug-FILE*.

A Tblgen Interactive Mode to evaluate expressions in a toplevel is included.
Type `M-x tblgen-run-caml' or see special-keys below.

Some elementary rules have to be followed in order to get the best of
indentation facilities.
  - Because the `function' keyword has a special indentation (to handle
    case matches) use the `fun' keyword when no case match is performed.
  - In OCaml, `;;' is no longer necessary for correct indentation,
    except before top level phrases not introduced by `type', `val', `let'
    etc. (i.e., phrases used for their side-effects or to be executed
    in a top level.)
  - Long sequences of `and's may slow down indentation slightly, since
    some computations (few) require to go back to the beginning of the
    sequence. Some very long nested blocks may also lead to slow
    processing of `end's, `else's, `done's...
  - Multiline strings are handled properly, but the string concatenation `^'
    is preferred to break long strings (the C-j keystroke can help).

Known bugs:
  - When writting a line with mixed code and comments, avoid putting
    comments at the beginning or middle of the text. More precisely, 
    writing comments immediately after `=' or parentheses then writing
    some more code on the line leads to indentation errors. You may write
    `let x (* blah *) = blah' but should avoid `let x = (* blah *) blah'.

Special keys for Tblgen mode:\\{tblgen-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (setq major-mode 'tblgen-mode)
  (setq mode-name "Tblgen")
  (use-local-map tblgen-mode-map)
  (set-syntax-table tblgen-mode-syntax-table)
  (setq local-abbrev-table tblgen-mode-abbrev-table)

  (tblgen-build-menu)

  (make-local-variable 'paragraph-start)
  (setq paragraph-start (concat "^[ \t]*$\\|\\*)$\\|" page-delimiter))
  (make-local-variable 'paragraph-separate)
  (setq paragraph-separate paragraph-start)
  (make-local-variable 'require-final-newline)
  (setq require-final-newline t)
  (make-local-variable 'comment-start)
  (setq comment-start "(* ")
  (make-local-variable 'comment-end)
  (setq comment-end " *)")
  (make-local-variable 'comment-column)
  (setq comment-column 40)
  (make-local-variable 'comment-start-skip)
  (setq comment-start-skip "(\\*+[ \t]*")
  (make-local-variable 'comment-multi-line)
  (setq comment-multi-line t)
  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments nil)
  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'tblgen-indent-command)
  (unless tblgen-use-syntax-ppss
    (make-local-hook 'before-change-functions)
    (add-hook 'before-change-functions 'tblgen-before-change-function nil t))
  (make-local-variable 'normal-auto-fill-function)
  (setq normal-auto-fill-function 'tblgen-auto-fill-function)
	 
  ;; Hooks for tblgen-mode, use them for tblgen-mode configuration
  (tblgen-install-font-lock)
  (run-hooks 'tblgen-mode-hook)
  (if tblgen-use-abbrev-mode (abbrev-mode 1))
  (message
   (concat "Major mode for editing and running Caml programs, "
	   tblgen-mode-version ".")))

(defun tblgen-install-font-lock (&optional no-sym-lock)
  (setq
   tblgen-font-lock-keywords
   (append
    (list
     (list "\\<\\(external\\|open\\|include\\|rule\\|s\\(ig\\|truct\\)\\|module\\|functor\\|with[ \t\n]+\\(type\\|module\\)\\|val\\|type\\|method\\|virtual\\|constraint\\|class\\|in\\|inherit\\|initializer\\|let\\|rec\\|and\\|begin\\|object\\|end\\)\\>"
	   0 'tblgen-font-lock-governing-face nil nil))
    (if tblgen-support-metaocaml
	(list (list "\\.<\\|>\\.\\|\\.~\\|\\.!"
		    0 'tblgen-font-lock-multistage-face nil nil))
      ())
    (list
     (list "\\<\\(false\\|true\\)\\>"
	   0 'font-lock-constant-face nil nil)
     (list "\\<\\(as\\|do\\(ne\\|wnto\\)?\\|else\\|for\\|if\\|m\\(atch\\|utable\\)\\|new\\|p\\(arser\\|rivate\\)\\|t\\(hen\\|o\\|ry\\)\\|w\\(h\\(en\\|ile\\)\\|ith\\)\\|lazy\\|exception\\|raise\\|failwith\\|exit\\|assert\\|fun\\(ction\\)?\\)\\>"
	   0 'font-lock-keyword-face nil nil)
     (list "[][;,()|{}]\\|[@^!:*=<>&/%+~?#---]\\.?\\|\\.\\.\\.*\\|\\<\\(asr\\|asl\\|lsr\\|lsl\\|l?or\\|l?and\\|xor\\|not\\|mod\\|of\\|ref\\)\\>"
	   0 'tblgen-font-lock-operator-face nil nil)
     (list (concat "\\<\\(\\(method\\([ \t\n]+\\(private\\|virtual\\)\\)?\\)\\([ \t\n]+virtual\\)?\\|val\\([ \t\n]+mutable\\)?\\|external\\|and\\|class\\|let\\([ \t\n]+rec\\)?\\)\\>[ \t\n]*\\(['_" tblgen-lower "]\\(\\w\\|[._]\\)*\\)\\>[ \t\n]*\\(\\(\\w\\|[()_?~.'*:--->]\\)+\\|=[ \t\n]*fun\\(ction\\)?\\>\\)")
	   8 'font-lock-function-name-face 'keep nil)
     (list "\\<method\\([ \t\n]+\\(private\\|virtual\\)\\)?\\>[ \t\n]*\\(\\(\\w\\|[_,?~.]\\)*\\)"
	   3 'font-lock-function-name-face 'keep nil)
     (list "\\<\\(fun\\(ction\\)?\\)\\>[ \t\n]*\\(\\(\\w\\|[_ \t()*,]\\)+\\)"
	   3 'font-lock-variable-name-face 'keep nil)
     (list "\\<\\(val\\([ \t\n]+mutable\\)?\\|external\\|and\\|class\\|let\\([ \t\n]+rec\\)?\\)\\>[ \t\n]*\\(\\(\\w\\|[_,?~.]\\)*\\)"
	   4 'font-lock-variable-name-face 'keep nil)
     (list "\\<\\(val\\([ \t\n]+mutable\\)?\\|external\\|method\\|and\\|class\\|let\\([ \t\n]+rec\\)?\\)\\>[ \t\n]*\\(\\(\\w\\|[_,?~.]\\)*\\)\\>\\(\\(\\w\\|[->_ \t,?~.]\\|(\\(\\w\\|[--->_ \t,?~.=]\\)*)\\)*\\)"
	   6 'font-lock-variable-name-face 'keep nil)
     (list "\\<\\(open\\|\\(class\\([ \t\n]+type\\)?\\)\\([ \t\n]+virtual\\)?\\|inherit\\|include\\|module\\([ \t\n]+\\(type\\|rec\\)\\)?\\|type\\)\\>[ \t\n]*\\(['~?]*\\([_--->.* \t]\\|\\w\\|(['~?]*\\([_--->.,* \t]\\|\\w\\)*)\\)*\\)"
	   7 'font-lock-type-face 'keep nil)
     (list "[^:>=]:[ \t\n]*\\(['~?]*\\([_--->.* \t]\\|\\w\\|(['~?]*\\([_--->.,* \t]\\|\\w\\)*)\\)*\\)"
	   1 'font-lock-type-face 'keep nil)
     (list "\\<\\([A-Z]\\w*\\>\\)[ \t]*\\."
	   1 'font-lock-type-face 'keep nil)
     (list (concat "\\<\\([?~]?[_" tblgen-alpha "]\\w*\\)[ \t\n]*:[^:>=]")
	   1 'font-lock-variable-name-face 'keep nil)
     (list (concat "\\<exception\\>[ \t\n]*\\(\\<[_" tblgen-alpha "]\\w*\\>\\)")
	   1 'font-lock-variable-name-face 'keep nil)
     (list "^#\\w+\\>"
	   0 'font-lock-preprocessor-face t nil))
    (if tblgen-font-lock-symbols
	(tblgen-font-lock-symbols-keywords)
      ())))
  (if (and (not no-sym-lock)
	   (featurep 'sym-lock))
      (progn
	(setq sym-lock-color
	      (face-foreground 'tblgen-font-lock-operator-face))
	(if (not sym-lock-keywords)
	    (sym-lock tblgen-sym-lock-keywords))))
  (setq font-lock-defaults
	(list*
	 'tblgen-font-lock-keywords (not tblgen-use-syntax-ppss) nil
	 tblgen-font-lock-syntax nil
	 '(font-lock-syntactic-keywords
	   . tblgen-font-lock-syntactic-keywords)
	 '(parse-sexp-lookup-properties
	   . t)
	 '(font-lock-syntactic-face-function
	   . tblgen-font-lock-syntactic-face-function)
	 (unless tblgen-use-syntax-ppss
	   '((font-lock-fontify-region-function
	      . tblgen-fontify-region)))))
  (when (and (boundp 'font-lock-fontify-region-function)
	     (not tblgen-use-syntax-ppss))
    (make-local-variable 'font-lock-fontify-region-function)
    (setq font-lock-fontify-region-function 'tblgen-fontify-region)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                               Error processing

(require 'compile)

;; In some versions of Emacs, the regexps in
;; compilation-error-regexp-alist do not match the error messages when
;; the language is not English. Hence we add a regexp.

(defconst tblgen-error-regexp
  "^[^\0-@]+ \"\\([^\"\n]+\\)\", [^\0-@]+ \\([0-9]+\\)[-,:]"
  "Regular expression matching the error messages produced by (o)camlc.")

(if (boundp 'compilation-error-regexp-alist)
    (or (assoc tblgen-error-regexp
               compilation-error-regexp-alist)
        (setq compilation-error-regexp-alist
              (cons (list tblgen-error-regexp 1 2)
               compilation-error-regexp-alist))))

;; A regexp to extract the range info.

(defconst tblgen-error-chars-regexp
  ".*, .*, [^\0-@]+ \\([0-9]+\\)-\\([0-9]+\\):"
  "Regexp matching the char numbers in an error message produced by (o)camlc.")

;; Wrapper around next-error.

;; itz 04-21-96 instead of defining a new function, use defadvice
;; that way we get our effect even when we do \C-x` in compilation buffer  

(defadvice next-error (after tblgen-next-error activate)
 "Read the extra positional information provided by the Caml compiler.

Puts the point and the mark exactly around the erroneous program
fragment. The erroneous fragment is also temporarily highlighted if
possible."
 (if (eq major-mode 'tblgen-mode)
     (let ((beg nil) (end nil))
       (save-excursion
	 (set-buffer compilation-last-buffer)
	 (save-excursion
	   (goto-char (window-point (get-buffer-window (current-buffer) t)))
	   (if (looking-at tblgen-error-chars-regexp)
	       (setq beg (string-to-number (tblgen-match-string 1))
		     end (string-to-number (tblgen-match-string 2))))))
       (beginning-of-line)
       (if beg
	   (progn
	     (setq beg (+ (point) beg) end (+ (point) end))
	     (goto-char beg) (push-mark end t t))))))

(defvar tblgen-interactive-error-regexp
  (concat "\\(\\("
	  "Toplevel input:"
	  "\\|Entr.e interactive:"
	  "\\|Characters [0-9-]*:"
	  "\\|The global value [^ ]* is referenced before being defined."
	  "\\|La valeur globale [^ ]* est utilis.e avant d'.tre d.finie."
	  "\\|Reference to undefined global"
	  "\\|The C primitive \"[^\"]*\" is not available."
	  "\\|La primitive C \"[^\"]*\" est inconnue."
	  "\\|Cannot find \\(the compiled interface \\)?file"
	  "\\|L'interface compil.e [^ ]* est introuvable."
	  "\\|Le fichier [^ ]* est introuvable."
	  "\\|Exception non rattrap.e:"
	  "\\|Uncaught exception:"
	  "\\)[^#]*\\)" )
  "Regular expression matching the error messages produced by Caml.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                               Indentation stuff

(defconst tblgen-keyword-regexp "\\<\\(object\\|initializer\\|and\\|c\\(onstraint\\|lass\\)\\|m\\(atch\\|odule\\|ethod\\|utable\\)\\|s\\(ig\\|truct\\)\\|begin\\|e\\(lse\\|x\\(ception\\|ternal\\)\\)\\|t\\(o\\|hen\\|ry\\|ype\\)\\|v\\(irtual\\|al\\)\\|w\\(h\\(ile\\|en\\)\\|ith\\)\\|i\\(f\\|n\\(herit\\)?\\)\\|f\\(or\\|un\\(ct\\(or\\|ion\\)\\)?\\)\\|let\\|do\\(wnto\\)?\\|parser?\\|rule\\|of\\)\\>\\|->\\|[;,|]"
  "Regexp for all recognized keywords.")

(defconst tblgen-match-|-keyword-regexp
  "\\<\\(and\\|fun\\(ction\\)?\\|type\\|with\\|parser?\\)\\>\\|[[({|=]"
  "Regexp for keywords supporting case match.")

(defconst tblgen-operator-regexp "[---+*/=<>@^&|]\\|:>\\|::\\|\\<\\(or\\|l\\(and\\|x?or\\|s[lr]\\)\\|as[lr]\\|mod\\)\\>"
  "Regexp for all operators.")

(defconst tblgen-kwop-regexp (concat tblgen-keyword-regexp "\\|=")
  "Regexp for all keywords, and the = operator which is generally
considered as a special keyword.")

(defconst tblgen-matching-keyword-regexp
  "\\<\\(and\\|do\\(ne\\)?\\|e\\(lse\\|nd\\)\\|in\\|then\\|\\(down\\)?to\\)\\>\\|>\\."
  "Regexp matching Caml keywords which act as end block delimiters.")

(defconst tblgen-leading-kwop-regexp
  (concat tblgen-matching-keyword-regexp "\\|\\<with\\>\\|[|>]?\\]\\|>?}\\|[|)]\\|;;")
  "Regexp matching Caml keywords which need special indentation.")

(defconst tblgen-governing-phrase-regexp
  "\\<\\(val\\|type\\|m\\(ethod\\|odule\\)\\|c\\(onstraint\\|lass\\)\\|in\\(herit\\|itializer\\)\\|ex\\(ternal\\|ception\\)\\|open\\|let\\|object\\|include\\)\\>"
  "Regexp matching tblgen phrase delimitors.")

(defconst tblgen-governing-phrase-regexp-with-break
  (concat tblgen-governing-phrase-regexp "\\|;;"))

(defconst tblgen-keyword-alist
  '(("module" . tblgen-default-indent)
    ("class" . tblgen-class-indent)
    ("sig" . tblgen-sig-struct-indent)
    ("struct" . tblgen-sig-struct-indent)
    ("method" . tblgen-method-indent)
    ("object" . tblgen-begin-indent)
    ("begin" . tblgen-begin-indent)
    (".<" . tblgen-begin-indent)
    ("for" . tblgen-for-while-indent)
    ("while" . tblgen-for-while-indent)
    ("do" . tblgen-do-indent)
    ("type" . tblgen-type-indent) ; in some cases, `type' acts like a match
    ("val" . tblgen-val-indent)
    ("fun" . tblgen-fun-indent)
    ("if" . tblgen-if-then-else-indent)
    ("then" . tblgen-if-then-else-indent)
    ("else" . tblgen-if-then-else-indent)
    ("let" . tblgen-let-indent)
    ("match" . tblgen-match-indent)
    ("try" . tblgen-try-indent)
    ("rule" . tblgen-rule-indent)

    ;; Case match keywords
    ("function" . tblgen-function-indent)
    ("with" . tblgen-with-indent)
    ("parse" . tblgen-parse-indent)
    ("parser" . tblgen-parser-indent)

    ;; Default indentation keywords
    ("when" . tblgen-default-indent)
    ("functor" . tblgen-default-indent)
    ("exception" . tblgen-default-indent)
    ("inherit" . tblgen-default-indent)
    ("initializer" . tblgen-default-indent)
    ("constraint" . tblgen-default-indent)
    ("virtual" . tblgen-default-indent)
    ("mutable" . tblgen-default-indent)
    ("external" . tblgen-default-indent)
    ("in" . tblgen-in-indent)
    ("of" . tblgen-default-indent)
    ("to" . tblgen-default-indent)
    ("downto" . tblgen-default-indent)
    (".<" . tblgen-default-indent)
    ("[" . tblgen-default-indent)
    ("(" . tblgen-default-indent)
    ("{" . tblgen-default-indent)
    ("->" . tblgen-default-indent)
    ("|" . tblgen-default-indent))
"Association list of indentation values based on governing keywords.")

(defconst tblgen-leading-kwop-alist
  '(("|" . tblgen-find-|-match)
    ("}" . tblgen-find-match)
    (">}" . tblgen-find-match)
    (">." . tblgen-find-match)
    (")" . tblgen-find-match)
    ("]" . tblgen-find-match)
    ("|]" . tblgen-find-match)
    (">]" . tblgen-find-match)
    ("end" . tblgen-find-match)
    ("done" . tblgen-find-done-match)
    ("in"  . tblgen-find-in-match)
    ("with" . tblgen-find-with-match)
    ("else" . tblgen-find-else-match)
    ("then" . tblgen-find-match)
    ("do" . tblgen-find-do-match)
    ("to" . tblgen-find-match)
    ("downto" . tblgen-find-match)
    ("and" . tblgen-find-and-match))
  "Association list used in Tblgen mode for skipping back over nested blocks.")

(defun tblgen-find-meaningful-word ()
  "Look back for a word, skipping comments and blanks.
Returns the actual text of the word, if found."
  (let ((found nil) (kwop nil))
    (while
	(and (not found)
	     (re-search-backward
	      (concat
	       "[^ \t\n_0-9" tblgen-alpha "]\\|\\<\\(\\w\\|_\\)+\\>\\|\\*)")
	      (point-min) t))
      (setq kwop (tblgen-match-string 0))
      (if kwop
	  (if (tblgen-in-comment-p)
	      (tblgen-beginning-of-literal-or-comment-fast)
	    (setq found t))
	(setq found t)))
    (if found kwop (goto-char (point-min)) nil)))

(defconst tblgen-find-kwop-regexp
  (concat tblgen-matching-keyword-regexp
	  "\\|\\<\\(for\\|while\\|do\\|if\\|begin\\|s\\(ig\\|truct\\)\\|object\\)\\>\\|[][(){}]\\|\\*)"))

(defun tblgen-make-find-kwop-regexp (kwop-regexp)
  (concat tblgen-find-kwop-regexp "\\|" kwop-regexp))

(defun tblgen-find-kwop (kr &optional do-not-skip-regexp)
  "Look back for a Caml keyword or operator matching KWOP-REGEXP.
Skips blocks etc...

Ignore occurences inside literals and comments.
If found, return the actual text of the keyword or operator."
  (let ((found nil)
	(kwop nil)
	(kwop-regexp (if tblgen-support-metaocaml
			 (concat kr "\\|\\.<\\|>\\.") kr)))
    (while (and (not found)
		(re-search-backward kwop-regexp (point-min) t)
		(setq kwop (tblgen-match-string 0)))
      (cond
       ((tblgen-in-literal-or-comment-p)
	(tblgen-beginning-of-literal-or-comment-fast))
       ((looking-at "[]})]")
	(tblgen-backward-up-list))
       ((tblgen-at-phrase-break-p)
	(setq found t))
       ((and do-not-skip-regexp (looking-at do-not-skip-regexp))
	(if (and (string= kwop "|") (char-equal ?| (preceding-char)))
	    (backward-char)
	  (setq found t)))
       ((looking-at tblgen-matching-keyword-regexp)
	(funcall (cdr (assoc (tblgen-match-string 0)
			     tblgen-leading-kwop-alist))))
       (t (setq found t))))
    (if found kwop (goto-char (point-min)) nil)))

(defun tblgen-find-match ()
  (tblgen-find-kwop tblgen-find-kwop-regexp))

(defconst tblgen-find-,-match-regexp
  (tblgen-make-find-kwop-regexp
   "\\<\\(and\\|match\\|begin\\|else\\|exception\\|then\\|try\\|with\\|or\\|fun\\|function\\|let\\|do\\)\\>\\|->\\|[[{(]"))
(defun tblgen-find-,-match ()
  (tblgen-find-kwop tblgen-find-,-match-regexp))

(defconst tblgen-find-with-match-regexp
  (tblgen-make-find-kwop-regexp
   "\\<\\(match\\|try\\|module\\|begin\\|with\\)\\>\\|[[{(]"))
(defun tblgen-find-with-match ()
  (let ((kwop (tblgen-find-kwop tblgen-find-with-match-regexp
				"\\<with\\>")))
    (if (string= kwop "with")
	(progn
	  (tblgen-find-with-match)
	  (tblgen-find-with-match)))
    kwop))

(defconst tblgen-find-in-match-regexp
  (tblgen-make-find-kwop-regexp "\\<let\\>"))
(defun tblgen-find-in-match ()
  (let ((kwop (tblgen-find-kwop tblgen-find-in-match-regexp "\\<and\\>")))
    (cond ((string= kwop "and") (tblgen-find-in-match))
	  (t kwop))))

(defconst tblgen-find-else-match-regexp
  (tblgen-make-find-kwop-regexp ";\\|->\\|\\<with\\>"))
(defun tblgen-find-else-match ()
  (let ((kwop (tblgen-find-kwop tblgen-find-else-match-regexp
				"->\\|\\<\\(with\\|then\\)\\>")))
    (cond
     ((string= kwop "then")
      (tblgen-find-match))
     ((string= kwop "with")
      (tblgen-find-with-match))
     ((string= kwop "->")
      (setq kwop (tblgen-find-->-match))
      (while (string= kwop "|")
	(setq kwop (tblgen-find-|-match)))
      (if (string= kwop "with")
	  (tblgen-find-with-match))
      (tblgen-find-else-match))
     ((string= kwop ";")
      (tblgen-find-semi-colon-match)
      (tblgen-find-else-match)))
    kwop))

(defun tblgen-find-do-match ()
  (let ((kwop (tblgen-find-kwop tblgen-find-kwop-regexp
				   "\\<\\(down\\)?to\\>")))
    (if (or (string= kwop "to") (string= kwop "downto"))
	(tblgen-find-match) kwop)))

(defun tblgen-find-done-match ()
  (let ((kwop (tblgen-find-kwop tblgen-find-kwop-regexp "\\<do\\>")))
    (if (string= kwop "do")
	(tblgen-find-do-match) kwop)))

(defconst tblgen-find-and-match-regexp
  "\\<\\(do\\(ne\\)?\\|e\\(lse\\|nd\\)\\|in\\|then\\|\\(down\\)?to\\)\\>\\|\\<\\(for\\|while\\|do\\|if\\|begin\\|s\\(ig\\|truct\\)\\|class\\)\\>\\|[][(){}]\\|\\*)\\|\\<\\(rule\\|exception\\|let\\|in\\|type\\|val\\|module\\)\\>")
(defconst tblgen-find-and-match-regexp-dnr
  (concat tblgen-find-and-match-regexp "\\|\\<and\\>"))
(defun tblgen-find-and-match (&optional do-not-recurse)
  (let* ((kwop (tblgen-find-kwop (if do-not-recurse
				     tblgen-find-and-match-regexp-dnr
				   tblgen-find-and-match-regexp)
				 "\\<and\\>"))
	 (old-point (point)))
    (cond ((or (string= kwop "type") (string= kwop "module"))
	   (let ((kwop2 (tblgen-find-meaningful-word)))
	     (cond ((string= kwop2 "with")
		    kwop2)
		   ((string= kwop2 "and")
		    (tblgen-find-and-match))
		   ((and (string= kwop "module")
			(string= kwop2 "let"))
		    kwop2)
		   (t (goto-char old-point) kwop))))
	  (t kwop))))

(defconst tblgen-find-=-match-regexp
  (tblgen-make-find-kwop-regexp "\\<\\(val\\|let\\|m\\(ethod\\|odule\\)\\|type\\|class\\|when\\|i[fn]\\)\\>\\|="))
(defun tblgen-find-=-match ()
  (let ((kwop (tblgen-find-kwop tblgen-find-=-match-regexp
				"\\<\\(and\\|in\\)\\>\\|=")))
    (cond
     ((string= kwop "and")
      (tblgen-find-and-match))
     ((and (string= kwop "=")
	   (not (tblgen-false-=-p)))
      (while (and (string= kwop "=")
		  (not (tblgen-false-=-p)))
	(setq kwop (tblgen-find-=-match)))
      kwop)
     (t kwop))))

(defun tblgen-if-when-= ()
  (save-excursion
    (tblgen-find-=-match)
    (looking-at "\\<\\(if\\|when\\)\\>")))

(defun tblgen-captive-= ()
  (save-excursion
    (tblgen-find-=-match)
    (looking-at "\\<\\(let\\|if\\|when\\|module\\|type\\|class\\)\\>")))

(defconst tblgen-find-|-match-regexp
  (tblgen-make-find-kwop-regexp
   "\\<\\(with\\|fun\\(ction\\)?\\|type\\|parser?\\)\\>\\|[=|]"))
(defun tblgen-find-|-match ()
  (let* ((kwop (tblgen-find-kwop tblgen-find-|-match-regexp
				 "\\<\\(and\\|with\\)\\>\\||"))
	 (old-point (point)))
    (cond ((string= kwop "and")
	   (setq old-point (point))
	   (setq kwop (tblgen-find-and-match))
	   (goto-char old-point)
	   kwop)
	  ((and (string= kwop "|")
		(looking-at "|[^|]")
		(tblgen-in-indentation-p))
	   kwop)
	  ((string= kwop "|") (tblgen-find-|-match))
	  ((and (string= kwop "=")
		(or (looking-at "=[ \t]*\\((\\*\\|$\\)")
		    (tblgen-false-=-p)
		    (not (string= (save-excursion (tblgen-find-=-match))
				  "type"))))
	   (tblgen-find-|-match))
	  ((string= kwop "parse")
	   (if (and (string-match "\\.mll" (buffer-name))
		    (save-excursion
		      (string= (tblgen-find-meaningful-word) "=")))
	       kwop (tblgen-find-|-match)))
	  (t kwop))))

(defconst tblgen-find-->-match-regexp
  (tblgen-make-find-kwop-regexp "\\<\\(external\\|val\\|method\\|let\\|with\\|fun\\(ction\\|ctor\\)?\\|parser\\)\\>\\|[|:;]"))
(defun tblgen-find-->-match ()
  (let ((kwop (tblgen-find-kwop tblgen-find-->-match-regexp "\\<with\\>")))
    (cond
     ((string= kwop "|")
      (if (tblgen-in-indentation-p)
	  kwop
	(progn (forward-char -1) (tblgen-find-->-match))))
     ((not (string= kwop ":")) kwop)
     ;; If we get this far, we know we're looking at a colon.
     ((or (char-equal (char-before) ?:)
	  (char-equal (char-after (1+ (point))) ?:)
	  (char-equal (char-after (1+ (point))) ?>))
      (tblgen-find-->-match))
     ;; Patch by T. Freeman
     (t (let ((oldpoint (point))
	      (match (tblgen-find-->-match)))
	  (if (looking-at ":")
	      match
	    (progn
	      ;; Go back to where we were before the recursive call.
	      (goto-char oldpoint)
	      kwop)))))))

(defconst tblgen-find-semi-colon-match-regexp
  (tblgen-make-find-kwop-regexp ";[ \t]*\\((\\*\\|$\\)\\|->\\|\\<\\(let\\|method\\|with\\|try\\|initializer\\)\\>"))
(defun tblgen-find-semi-colon-match (&optional leading-semi-colon)
  (tblgen-find-kwop tblgen-find-semi-colon-match-regexp
			 "\\<\\(in\\|end\\|and\\|do\\|with\\)\\>")
  ;; We don't need to find the keyword matching `and' since we know it's `let'!
  (cond
   ((looking-at ";[ \t]*\\((\\*\\|$\\)")
    (forward-line 1)
    (while (or (tblgen-in-comment-p)
	       (looking-at "^[ \t]*\\((\\*\\|$\\)"))
      (forward-line 1))
    (back-to-indentation)
    (current-column))
   ((and leading-semi-colon
	 (looking-at "\\((\\|\\[[<|]?\\|{<?\\)[ \t]*[^ \t\n]")
	 (not (looking-at "[[{(][|<]?[ \t]*\\((\\*\\|$\\)")))
    (current-column))
   ((looking-at "\\((\\|\\[[<|]?\\|{<?\\)[ \t]*\\((\\*\\|$\\)")
    (tblgen-back-to-paren-or-indentation t)
    (+ (current-column) tblgen-default-indent))
   ((looking-at "\\(\\.<\\|(\\|\\[[<|]?\\|{<?\\)[ \t]*[^ \t\n]")
    (tblgen-search-forward-paren)
    (current-column))
   ((looking-at "\\<method\\>[ \t]*\\((\\*\\|$\\)")
    (tblgen-back-to-paren-or-indentation)
    (+ (current-column) tblgen-method-indent))
   ((looking-at "\\<begin\\>[ \t]*\\((\\*\\|$\\)")
    (tblgen-back-to-paren-or-indentation t)
    (+ (current-column) tblgen-begin-indent))
   ((looking-at "->")
    (if (save-excursion
	  (tblgen-find-->-match)
	  (looking-at "\\<\\(with\\|fun\\(ction\\)?\\|parser\\)\\>\\||"))
	(progn
	  (tblgen-back-to-paren-or-indentation)
	  (+ (current-column) tblgen-default-indent))
      (tblgen-find-semi-colon-match)))
   ((looking-at "\\<end\\>")
    (tblgen-find-match)
    (tblgen-find-semi-colon-match))
   ((looking-at "\\<in\\>")
    (tblgen-find-in-match)
    (tblgen-back-to-paren-or-indentation)
    (+ (current-column) tblgen-in-indent))
   ((looking-at "\\<let\\>")
    (+ (current-column) tblgen-let-indent))
   (t (tblgen-back-to-paren-or-indentation t)
      (+ (current-column) tblgen-default-indent))))

(defconst tblgen-find-phrase-indentation-regexp
  (tblgen-make-find-kwop-regexp (concat tblgen-governing-phrase-regexp
					"\\|\\<and\\>")))
(defconst tblgen-find-phrase-indentation-regexp-pb
  (concat tblgen-find-phrase-indentation-regexp "\\|;;"))
(defconst tblgen-find-phrase-indentation-class-regexp
  (concat tblgen-matching-keyword-regexp "\\|\\<class\\>"))
(defun tblgen-find-phrase-indentation (&optional phrase-break)
  (if (and (looking-at "\\<\\(type\\|module\\)\\>") (> (point) (point-min))
	   (save-excursion
	     (tblgen-find-meaningful-word)
	     (looking-at "\\<\\(module\\|with\\|and\\|let\\)\\>")))
      (progn
	(tblgen-find-meaningful-word)
	(+ (current-column) tblgen-default-indent))
    (let ((looking-at-and (looking-at "\\<and\\>"))
	  (kwop (tblgen-find-kwop
		 (if phrase-break
		     tblgen-find-phrase-indentation-regexp-pb
		   tblgen-find-phrase-indentation-regexp)
		 "\\<\\(end\\|and\\|with\\|in\\)\\>"))
	  (tmpkwop nil) (curr nil))
      (if (and kwop (string= kwop "and"))
	  (setq kwop (tblgen-find-and-match)))
      (if (not kwop) (current-column)
	(cond
	 ((string= kwop "end")
	  (if (not (save-excursion
		     (setq tmpkwop (tblgen-find-match))
		     (setq curr (point))
		     (string= tmpkwop "object")))
	      (progn
		(tblgen-find-match)
		(tblgen-find-phrase-indentation phrase-break))
	    (tblgen-find-kwop tblgen-find-phrase-indentation-class-regexp)
	    (current-column)))
	 ((and (string= kwop "with")
	       (not (save-excursion
		      (setq tmpkwop (tblgen-find-with-match))
		      (setq curr (point))
		      (string= tmpkwop "module"))))
	  (goto-char curr)
	  (tblgen-find-phrase-indentation phrase-break))
	 ((and (string= kwop "in")
	       (not (save-excursion
		      (setq tmpkwop (tblgen-find-in-match))
		      (if (string= tmpkwop "and")
			  (setq tmpkwop (tblgen-find-and-match)))
		      (setq curr (point))
		      (and (string= tmpkwop "let")
			   (not (tblgen-looking-at-expression-let))))))
	  (goto-char curr)
	  (tblgen-find-phrase-indentation phrase-break))
	 ((tblgen-at-phrase-break-p)
	  (end-of-line)
	  (tblgen-skip-blank-and-comments)
	  (current-column))
	 ((string= kwop "let")
	  (if (tblgen-looking-at-expression-let)
	      (tblgen-find-phrase-indentation phrase-break)
	    (current-column)))
	 ((string= kwop "with")
	  (current-column))
	 ((string= kwop "end")
	  (current-column))
	 ((string= kwop "in")
	  (tblgen-find-in-match)
	  (current-column))
	 ((string= kwop "class")
	  (tblgen-back-to-paren-or-indentation)
	  (current-column))
	 ((looking-at "\\<\\(object\\|s\\(ig\\|truct\\)\\)\\>")
	  (tblgen-back-to-paren-or-indentation t)
	  (+ (tblgen-assoc-indent kwop) (current-column)))
	 ((or (string= kwop "type") (string= kwop "module"))
	  (if (or (tblgen-looking-at-false-type)
		  (tblgen-looking-at-false-module))
	      (if looking-at-and (current-column)
		(tblgen-find-meaningful-word)
		(if (looking-at "\\<and\\>")
		    (progn
		      (tblgen-find-and-match)
		      (tblgen-find-phrase-indentation phrase-break))
		  (tblgen-find-phrase-indentation phrase-break)))
	    (current-column)))
	 ((looking-at
	   "\\(\\.<\\|(\\|\\[[<|]?\\|{<?\\)[ \t]*\\((\\*\\|$\\)")
	  (tblgen-back-to-paren-or-indentation)
	  (+ (current-column) tblgen-default-indent))
	 ((looking-at "\\(\\.<\\|(\\|\\[[<|]?\\|{<?\\)[ \t]*[^ \t\n]")
	  (tblgen-search-forward-paren)
	  (current-column))
	 ((string= kwop "open") ; compatible with Caml Light `#open'
	  (tblgen-back-to-paren-or-indentation) (current-column))
	 (t (current-column)))))))

(defconst tblgen-back-to-paren-or-indentation-regexp
  "[][(){}]\\|\\.<\\|>\\.\\|\\*)\\|^[ \t]*\\(.\\|\n\\)")
(defconst tblgen-back-to-paren-or-indentation-in-regexp
  (concat "\\<in\\>\\|" tblgen-back-to-paren-or-indentation-regexp))
(defconst tblgen-back-to-paren-or-indentation-lazy-regexp
  "[])}]\\|\\.<\\|>\\.\\|\\*)\\|^[ \t]*\\(.\\|\n\\)")
(defconst tblgen-back-to-paren-or-indentation-lazy-in-regexp
  (concat "\\<in\\>\\|" tblgen-back-to-paren-or-indentation-regexp))
(defun tblgen-back-to-paren-or-indentation (&optional forward-in)
  "Search backwards for the first open paren in line, or skip to indentation.
Returns t iff skipped to indentation."
  (if (or (bolp) (tblgen-in-indentation-p)) (progn (back-to-indentation) t)
    (let ((kwop (tblgen-find-kwop
		 (if tblgen-lazy-paren
		     (if forward-in
			 tblgen-back-to-paren-or-indentation-lazy-in-regexp
		       tblgen-back-to-paren-or-indentation-lazy-regexp)
		   (if forward-in
		       tblgen-back-to-paren-or-indentation-in-regexp
		     tblgen-back-to-paren-or-indentation-regexp))
		 "\\<and\\|with\\|in\\>"))
	  (retval))
      (if (string= kwop "with")
	  (let ((with-point (point)))
	    (setq kwop (tblgen-find-with-match))
	    (if (or (string= kwop "match") (string= kwop "try"))
		(tblgen-find-kwop
		 tblgen-back-to-paren-or-indentation-regexp
		 "\\<and\\>")
	      (setq kwop "with") (goto-char with-point))))
      (setq retval
	    (cond
	     ((string= kwop "with") nil)
	     ((string= kwop "in") (tblgen-in-indentation-p))
	     ((looking-at "[[{(]") (tblgen-search-forward-paren) nil)
	     ((looking-at "\\.<")
	      (if tblgen-support-metaocaml
		  (progn
		    (tblgen-search-forward-paren) nil)
		(tblgen-back-to-paren-or-indentation forward-in)))
	     (t (back-to-indentation) t)))
      (cond
       ((looking-at "|[^|]")
	(re-search-forward "|[^|][ \t]*") nil)
       ((and forward-in (string= kwop "in"))
	(tblgen-find-in-match)
	(tblgen-back-to-paren-or-indentation forward-in)
	(if (looking-at "\\<\\(let\\|and\\)\\>")
	    (forward-char tblgen-in-indent)) nil)
       (t retval)))))

(defun tblgen-search-forward-paren ()
  (if tblgen-lazy-paren (tblgen-back-to-paren-or-indentation)
    (re-search-forward "\\(\\.<\\|(\\|\\[[<|]?\\|{<?\\)[ \t]*")))

(defun tblgen-add-default-indent (leading-operator)
  (if leading-operator 0 tblgen-default-indent))

(defconst tblgen-compute-argument-indent-regexp
  (tblgen-make-find-kwop-regexp tblgen-kwop-regexp))
(defun tblgen-compute-argument-indent (leading-operator)
  (let ((old-point (save-excursion (beginning-of-line) (point)))
	(match-end-point) (kwop))
    (setq kwop (tblgen-find-kwop tblgen-compute-argument-indent-regexp
				 tblgen-keyword-regexp))
    (setq match-end-point (+ (point) (length kwop))) ; match-end is invalid !
    (cond
     ((and (string= kwop "->")
	   (not (looking-at "->[ \t]*\\((\\*.*\\)?$")))
      (let* (matching-kwop matching-pos)
	(save-excursion
	  (setq matching-kwop (tblgen-find-->-match))
	  (setq matching-pos (point)))
	(cond
	 ((string= matching-kwop ":")
	  (goto-char matching-pos)
	  (tblgen-find-->-match) ; matching `val' or `let'
	  (+ (current-column) tblgen-val-indent))
	 ((string= matching-kwop "|")
	  (goto-char matching-pos)
	  (+ (tblgen-add-default-indent leading-operator)
	     (current-column) tblgen-|-extra-unindent tblgen-default-indent))
	 (t
	  (tblgen-back-to-paren-or-indentation)
	  (+ (tblgen-add-default-indent leading-operator) (current-column))))))
     ((string= kwop "fun")
      (tblgen-back-to-paren-or-indentation t)
      (+ (current-column)
	 (tblgen-assoc-indent kwop)))
     ((<= old-point (point))
      (+ (tblgen-add-default-indent leading-operator) (current-column)))
     (t
      (forward-line 1)
      (beginning-of-line)
      (while (or (tblgen-in-comment-p) (looking-at "^[ \t]*\\((\\*.*\\)?$"))
	(forward-line 1))
      (tblgen-back-to-paren-or-indentation)
      (if (save-excursion (goto-char match-end-point)
			  (looking-at "[ \t]*\\((\\*.*\\)?$"))
	  (+ (tblgen-add-default-indent leading-operator)
	     (current-column))
	(current-column))))))

(defun tblgen-indent-from-paren (&optional leading-operator)
  (if (looking-at
       "\\(\\.<\\|(\\|\\[[<|]?\\|{<?\\)[ \t]*\\((\\*\\|$\\)")
      (progn
	(tblgen-back-to-paren-or-indentation t)
	(+ tblgen-default-indent
	   (current-column))) ; parens do not operate
    (tblgen-search-forward-paren)
    (+ (tblgen-add-default-indent leading-operator)
       (current-column))))

(defconst tblgen-compute-normal-indent-regexp
  (concat tblgen-compute-argument-indent-regexp "\\|^.[ \t]*"))
(defun tblgen-compute-normal-indent ()
  (let ((leading-operator (looking-at tblgen-operator-regexp)))
    (beginning-of-line)
    ;; Operator ending previous line used to be considered leading
    ;; (save-excursion
    ;;  (tblgen-find-meaningful-word)
    ;;  (if (looking-at tblgen-operator-regexp)
    ;;	  (setq leading-operator t)))
    (save-excursion
      (let ((kwop (tblgen-find-kwop (if leading-operator
					tblgen-compute-argument-indent-regexp
				      tblgen-compute-normal-indent-regexp)
				    tblgen-keyword-regexp)))
	(if (string= kwop "and") (setq kwop (tblgen-find-and-match)))
	(while (or (and (string= kwop "=")
			(tblgen-false-=-p))
		   (and (looking-at "^[ \t]*\\((\\*.*\\)?$")
			(not (= (point) (point-min)))))
	  (setq kwop (tblgen-find-kwop tblgen-compute-normal-indent-regexp
				       tblgen-keyword-regexp))
	  (if (string= kwop "and") (setq kwop (tblgen-find-and-match))))
	(if (not kwop) (current-column)
	  (cond
	   ((tblgen-at-phrase-break-p)
	    (tblgen-find-phrase-indentation t))
	   ((and (string= kwop "|") (not  (char-equal ?\[ (preceding-char))))
	    (tblgen-backward-char)
	    (tblgen-back-to-paren-or-indentation)
	    (+ (current-column) tblgen-default-indent
	       (tblgen-add-default-indent leading-operator)))
	   ((or (looking-at "[[{(]")
		(and (looking-at "[<|]")
		     (char-equal ?\[ (preceding-char))
		     (progn (tblgen-backward-char) t))
		(and (looking-at "<")
		     (char-equal ?\{ (preceding-char))
		     (progn (tblgen-backward-char) t)))
	    (tblgen-indent-from-paren leading-operator))
	   ((looking-at "\\.<")
	    (tblgen-indent-from-paren leading-operator))
	   ((looking-at "->")
	    (let ((keyword-->-match (save-excursion (tblgen-find-->-match))))
	      (cond ((string= keyword-->-match "|")
		     (tblgen-find-->-match)
		     (re-search-forward "|[ \t]*")
		     (+ (current-column) tblgen-default-indent))
		    ((string= keyword-->-match ":")
		     (tblgen-find-->-match) ; slow, better to save the column
		     (tblgen-find-->-match) ; matching `val' or `let'
		     (+ (current-column) tblgen-val-indent))
		    (t (tblgen-back-to-paren-or-indentation)
		       (+ tblgen-default-indent (current-column))))))
	   ((looking-at tblgen-keyword-regexp)
	    (cond ((string= kwop ";")
		   (if (looking-at ";[ \t]*\\((\\*\\|$\\)")
		       (tblgen-find-semi-colon-match)
		     (tblgen-back-to-paren-or-indentation t)
		     (+ (current-column) tblgen-default-indent)))
		  ((string= kwop ",")
		   (if (looking-at ",[ \t]*\\((\\*\\|$\\)")
		       (progn
			 (setq kwop (tblgen-find-,-match))
			 (if (or (looking-at "[[{(]\\|\\.<")
				 (and (looking-at "[<|]")
				      (char-equal ?\[ (preceding-char))
				      (progn (tblgen-backward-char) t))
				 (and (looking-at "<")
				      (char-equal ?\{ (preceding-char))
				      (progn (tblgen-backward-char) t)))
			     (tblgen-indent-from-paren t)
			   (tblgen-back-to-paren-or-indentation t)
			   (+ (current-column)
			      (tblgen-assoc-indent kwop))))
		     (tblgen-back-to-paren-or-indentation t)
		     (+ (current-column) tblgen-default-indent)))
		  ((and (looking-at "\\<\\(in\\|begin\\|do\\)\\>\\|->")
			(not (looking-at
			      "\\([a-z]+\\|->\\)[ \t]*\\((\\*\\|$\\)")))
		   (if (string= kwop "in")
		       (re-search-forward "\\<in\\>[ \t]*")
		     (tblgen-back-to-paren-or-indentation t))
		   (+ (current-column)
		      (tblgen-add-default-indent leading-operator)
		      (if (string= kwop "in") 0 ; aligned, do not indent
			(tblgen-assoc-indent kwop))))
		  ((string= kwop "with")
		   (if (save-excursion
			 (let ((tmpkwop (tblgen-find-with-match)))
			   (or (string= tmpkwop "module")
			       (string= tmpkwop "{"))))
		       (progn
			 (tblgen-back-to-paren-or-indentation)
			 (+ (current-column) tblgen-default-indent))
		     (tblgen-back-to-paren-or-indentation)
		     (+ (current-column)
			(tblgen-assoc-indent kwop t))))
		  ((string= kwop "in")
		   (tblgen-find-in-match)
		   (tblgen-back-to-paren-or-indentation)
		   (+ (current-column) tblgen-in-indent))
		  ((or (string= kwop "let") (string= kwop "and"))
		   (tblgen-back-to-paren-or-indentation t)
		   (+ (current-column)
		      tblgen-default-indent
		      (tblgen-assoc-indent kwop t)))
		  (t (tblgen-back-to-paren-or-indentation t)
		     (+ (current-column)
			(tblgen-assoc-indent kwop t)))))
	   ((and (looking-at "=") (not (tblgen-false-=-p)))
	    (let ((current-column-module-type nil))
	      (+
	       (progn
		 (tblgen-find-=-match)
		 (save-excursion
		   (if (looking-at "\\<and\\>") (tblgen-find-and-match))
		   (cond
		    ((looking-at "\\<type\\>")
		     (tblgen-find-meaningful-word)
		     (if (looking-at "\\<module\\>")
			 (progn
			   (setq current-column-module-type (current-column))
			   tblgen-default-indent)
		       (if (looking-at "\\<\\(with\\|and\\)\\>")
			   (progn
			     (tblgen-find-with-match)
			     (setq current-column-module-type (current-column))
			     tblgen-default-indent)
			 (re-search-forward "\\<type\\>")
			 (beginning-of-line)
			 (+ tblgen-type-indent
			    tblgen-|-extra-unindent))))
		    ((looking-at
		      "\\<\\(val\\|let\\|m\\(ethod\\|odule\\)\\|class\\|when\\|\\|for\\|if\\)\\>")
		     (let ((matched-string (tblgen-match-string 0)))
		       (tblgen-back-to-paren-or-indentation t)
		       (setq current-column-module-type (current-column))
		       (tblgen-assoc-indent matched-string)))
		    ((looking-at "\\<object\\>")
		     (tblgen-back-to-paren-or-indentation t)
		     (setq current-column-module-type (current-column))
		     (+ (tblgen-assoc-indent "object")
			tblgen-default-indent))
		    (t (tblgen-back-to-paren-or-indentation t)
		       (setq current-column-module-type
			     (+ (current-column) tblgen-default-indent))
		       tblgen-default-indent))))
	       (if current-column-module-type
		   current-column-module-type
		 (current-column)))))
	   (nil 0)
	   (t (tblgen-compute-argument-indent leading-operator))))))))

(defun tblgen-looking-at-expression-let ()
  (save-excursion
    (tblgen-find-meaningful-word)
    (and (not (tblgen-at-phrase-break-p))
	 (not (and tblgen-support-metaocaml
		   (looking-at "\\.")
		   (char-equal ?> (preceding-char))))
	 (or (looking-at "[[({;=]\\|\\<\\(begin\\|i[fn]\\|do\\|t\\(ry\\|hen\\)\\|else\\|match\\|wh\\(ile\\|en\\)\\)\\>")
	     (looking-at tblgen-operator-regexp)))))

(defun tblgen-looking-at-false-module ()
  (save-excursion (tblgen-find-meaningful-word)
		  (looking-at "\\<\\(let\\|with\\|and\\)\\>")))

(defun tblgen-looking-at-false-sig-struct ()
  (save-excursion (tblgen-find-module)
		  (looking-at "\\<module\\>")))

(defun tblgen-looking-at-false-type ()
  (save-excursion (tblgen-find-meaningful-word)
		  (looking-at "\\<\\(class\\|with\\|module\\|and\\)\\>")))

(defun tblgen-looking-at-in-let ()
  (save-excursion (string= (tblgen-find-meaningful-word) "in")))

(defconst tblgen-find-module-regexp
  (tblgen-make-find-kwop-regexp "\\<module\\>"))
(defun tblgen-find-module ()
  (tblgen-find-kwop tblgen-find-module-regexp))

(defun tblgen-modify-syntax ()
  "Switch to modified internal syntax."
  (modify-syntax-entry ?. "w" tblgen-mode-syntax-table)
  (modify-syntax-entry ?_ "w" tblgen-mode-syntax-table))

(defun tblgen-restore-syntax ()
  "Switch back to interactive syntax."
  (modify-syntax-entry ?. "." tblgen-mode-syntax-table)
  (modify-syntax-entry ?_ "_" tblgen-mode-syntax-table))

(defun tblgen-indent-command (&optional from-leading-star)
  "Indent the current line in Tblgen mode.

Compute new indentation based on Caml syntax."
  (interactive "*")
    (if (not from-leading-star)
	(tblgen-auto-fill-insert-leading-star))
  (let ((case-fold-search nil))
    (tblgen-modify-syntax)
    (save-excursion
      (back-to-indentation)
      (indent-line-to (tblgen-compute-indent)))
    (if (tblgen-in-indentation-p) (back-to-indentation))
    (tblgen-restore-syntax)))

(defun tblgen-compute-indent ()
  (save-excursion
    (cond
     ((tblgen-in-comment-p)
      (cond
       ((looking-at "(\\*")
	(if tblgen-indent-leading-comments
	    (save-excursion
	      (while (and (progn (beginning-of-line)
				 (> (point) 1))
			  (progn (forward-line -1)
				 (back-to-indentation)
				 (tblgen-in-comment-p))))
	      (if (looking-at "[ \t]*$")
		  (progn
		    (tblgen-skip-blank-and-comments)
		    (if (or (looking-at "$") (tblgen-in-comment-p))
			0
		      (tblgen-compute-indent)))
		(forward-line 1)
		(tblgen-compute-normal-indent)))
	  (current-column)))
       ((looking-at "\\*\\**)")
	(tblgen-beginning-of-literal-or-comment-fast)
	(if (tblgen-leading-star-p)
	    (+ (current-column)
	       (if (save-excursion
		     (forward-line 1)
		     (back-to-indentation)
		     (looking-at "*")) 1
		 tblgen-comment-end-extra-indent))
	  (+ (current-column) tblgen-comment-end-extra-indent)))
       (tblgen-indent-comments
	(let ((star (and (tblgen-leading-star-p)
			 (looking-at "\\*"))))
	  (tblgen-beginning-of-literal-or-comment-fast)
	  (if star (re-search-forward "(") (re-search-forward "(\\*+[ \t]*"))
	  (current-column)))
       (t (current-column))))
     ((tblgen-in-literal-p)
      (current-column))
     ((looking-at "\\<let\\>")
      (if (tblgen-looking-at-expression-let)
	  (if (tblgen-looking-at-in-let)
	      (progn
		(tblgen-find-meaningful-word)
		(tblgen-find-in-match)
		(tblgen-back-to-paren-or-indentation)
		(current-column))
	    (tblgen-compute-normal-indent))
	(tblgen-find-phrase-indentation)))
     ((looking-at tblgen-governing-phrase-regexp-with-break)
      (tblgen-find-phrase-indentation))
     ((and tblgen-sig-struct-align (looking-at "\\<\\(sig\\|struct\\)\\>"))
      (if (string= (tblgen-find-module) "module") (current-column)
	(tblgen-back-to-paren-or-indentation)
	(+ tblgen-default-indent (current-column))))
     ((looking-at ";") (tblgen-find-semi-colon-match t))
     ((or (looking-at "%\\|;;")
	  (and tblgen-support-camllight (looking-at "#"))
	  (looking-at "#\\<\\(open\\|load\\|use\\)\\>")) 0)
     ((or (looking-at tblgen-leading-kwop-regexp)
	  (and tblgen-support-metaocaml
	       (looking-at ">\\.")))
      (let ((kwop (tblgen-match-string 0)))
	(let* ((old-point (point))
	       (paren-match-p (looking-at "[|>]?[]})]\\|>\\."))
	       (need-not-back-kwop (string= kwop "and"))
	       (real-| (looking-at "|\\([^|]\\|$\\)"))
	       (matching-kwop
		(if (string= kwop "and")
		    (tblgen-find-and-match t)
		  (funcall (cdr (assoc kwop tblgen-leading-kwop-alist)))))
	       (match-|-keyword-p
		(and matching-kwop
		     (looking-at tblgen-match-|-keyword-regexp))))
	  (cond
	   ((and (string= kwop "|") real-|)
	    (cond
	     ((string= matching-kwop "|")
	      (if (not need-not-back-kwop)
		  (tblgen-back-to-paren-or-indentation))
	      (current-column))
	     ((and (string= matching-kwop "=")
		   (not (tblgen-false-=-p)))
	      (re-search-forward "=[ \t]*")
	      (current-column))
	     (match-|-keyword-p
	      (if (not need-not-back-kwop)
		  (tblgen-back-to-paren-or-indentation))
	      (- (+ (tblgen-assoc-indent
		     matching-kwop t)
		    (current-column))
		 (if (string= matching-kwop "type") 0
		   tblgen-|-extra-unindent)))
	     (t (goto-char old-point)
		(tblgen-compute-normal-indent))))
	   ((and (string= kwop "|") (not real-|))
	    (goto-char old-point)
	    (tblgen-compute-normal-indent))
	   ((and
	     (looking-at "\\(\\[|?\\|{<?\\|(\\|\\.<\\)[ \t]*[^ \t\n]")
	     (not (looking-at "\\([[{(][|<]?\\|\\.<\\)[ \t]*\\((\\*\\|$\\)")))
	    (if (and (string= kwop "|") real-|)
		(current-column)
	      (if (not paren-match-p)
		  (tblgen-search-forward-paren))
	      (if tblgen-lazy-paren
		  (tblgen-back-to-paren-or-indentation))
	      (current-column)))
	   ((and (string= kwop "with")
		 (or (string= matching-kwop "module")
		     (string= matching-kwop "struct")))
	    (tblgen-back-to-paren-or-indentation nil)
	    (+ (current-column) tblgen-default-indent))
	   ((not need-not-back-kwop)
	    (tblgen-back-to-paren-or-indentation (not (string= kwop "in")))
	    (current-column))
	   (t (current-column))))))
     (t (tblgen-compute-normal-indent)))))

(defun tblgen-split-string ()
  "Called whenever a line is broken inside a Caml string literal."
  (insert-before-markers "\" ^\"")
  (tblgen-backward-char))

(defadvice newline-and-indent (around
			       tblgen-newline-and-indent
			       activate)
  "Handle multi-line strings in Tblgen mode."
    (let ((hooked (and (eq major-mode 'tblgen-mode) (tblgen-in-literal-p)))
	  (split-mark))
      (if (not hooked) nil
	(setq split-mark (set-marker (make-marker) (point)))
	(tblgen-split-string))
      ad-do-it
      (if (not hooked) nil
	(goto-char split-mark)
	(set-marker split-mark nil))))

(defun tblgen-electric ()
  "If inserting a | operator at beginning of line, reindent the line."
  (interactive "*")
  (let ((electric (and tblgen-electric-indent
		       (tblgen-in-indentation-p)
		       (not (tblgen-in-literal-p))
		       (not (tblgen-in-comment-p)))))
    (self-insert-command 1)
    (if (and electric
	     (not (and (char-equal ?| (preceding-char))
		       (save-excursion
			 (tblgen-backward-char)
			 (tblgen-find-|-match)
			 (not (looking-at tblgen-match-|-keyword-regexp))))))
	(indent-according-to-mode))))

(defun tblgen-electric-rp ()
  "If inserting a ) operator or a comment-end at beginning of line,
reindent the line."
  (interactive "*")
  (let ((electric (and tblgen-electric-indent
		       (or (tblgen-in-indentation-p)
			   (char-equal ?* (preceding-char)))
		       (not (tblgen-in-literal-p))
		       (or (not (tblgen-in-comment-p))
			   (save-excursion
			     (back-to-indentation)
			     (looking-at "\\*"))))))
    (self-insert-command 1)
    (if electric
	(indent-according-to-mode))))

(defun tblgen-electric-rc ()
  "If inserting a } operator at beginning of line, reindent the line.

Reindent also if } is inserted after a > operator at beginning of line.
Also, if the matching { is followed by a < and this } is not preceded
by >, insert one >."
  (interactive "*")
  (let* ((prec (preceding-char))
	 (look-bra (and tblgen-electric-close-vector
			(not (tblgen-in-literal-or-comment-p))
			(not (char-equal ?> prec))))
	 (electric (and tblgen-electric-indent
			(or (tblgen-in-indentation-p)
			    (and (char-equal ?> prec)
				 (save-excursion (tblgen-backward-char)
						 (tblgen-in-indentation-p))))
			(not (tblgen-in-literal-or-comment-p)))))
    (self-insert-command 1)
    (if look-bra
	(save-excursion
	  (let ((inserted-char
		 (save-excursion
		   (tblgen-backward-char)
		   (tblgen-backward-up-list)
		   (cond ((looking-at "{<") ">")
			 (t "")))))
	    (tblgen-backward-char)
	    (insert inserted-char))))
    (if electric (indent-according-to-mode))))

(defun tblgen-electric-rb ()
  "If inserting a ] operator at beginning of line, reindent the line.

Reindent also if ] is inserted after a | operator at beginning of line.
Also, if the matching [ is followed by a | and this ] is not preceded
by |, insert one |."
  (interactive "*")
  (let* ((prec (preceding-char))
	 (look-|-or-bra (and tblgen-electric-close-vector
			     (not (tblgen-in-literal-or-comment-p))
			     (not (and (char-equal ?| prec)
				       (not (char-equal
					     (save-excursion
					       (tblgen-backward-char)
					       (preceding-char)) ?\[))))))
	 (electric (and tblgen-electric-indent
			(or (tblgen-in-indentation-p)
			    (and (char-equal ?| prec)
				 (save-excursion (tblgen-backward-char)
						 (tblgen-in-indentation-p))))
			(not (tblgen-in-literal-or-comment-p)))))
    (self-insert-command 1)
    (if look-|-or-bra
	(save-excursion
	  (let ((inserted-char
		 (save-excursion
		   (tblgen-backward-char)
		   (tblgen-backward-up-list)
		   (cond ((looking-at "\\[|") "|")
			 (t "")))))
	    (tblgen-backward-char)
	    (insert inserted-char))))
    (if electric (indent-according-to-mode))))

(defun tblgen-abbrev-hook ()
  "If inserting a leading keyword at beginning of line, reindent the line."
  (if (not (tblgen-in-literal-or-comment-p))
      (let* ((bol (save-excursion (beginning-of-line) (point)))
	     (kw (save-excursion
		   (and (re-search-backward "^[ \t]*\\(\\w\\|_\\)+\\=" bol t)
			(tblgen-match-string 1)))))
	(if kw (progn
		   (insert " ")
		   (indent-according-to-mode)
		   (backward-delete-char-untabify 1))))))

(defun tblgen-skip-to-end-of-phrase ()
  (let ((old-point (point)))
    (if (and (string= (tblgen-find-meaningful-word) ";")
	     (char-equal (preceding-char) ?\;))
	(setq old-point (1- (point))))
    (goto-char old-point)
    (let ((kwop (tblgen-find-meaningful-word)))
      (goto-char (+ (point) (length kwop))))))

(defun tblgen-skip-blank-and-comments ()
  (skip-chars-forward " \t\n")
  (while (and (not (eobp)) (tblgen-in-comment-p)
	      (search-forward "*)" nil t))
    (skip-chars-forward " \t\n")))

(defun tblgen-skip-back-blank-and-comments ()
  (skip-chars-backward " \t\n")
  (while (save-excursion (tblgen-backward-char)
			 (and (> (point) (point-min)) (tblgen-in-comment-p)))
    (tblgen-backward-char)
    (tblgen-beginning-of-literal-or-comment) (skip-chars-backward " \t\n")))

(defconst tblgen-beginning-phrase-regexp
  "^#[ \t]*[a-z][_a-z]*\\>\\|\\<\\(end\\|type\\|module\\|sig\\|struct\\|class\\|exception\\|open\\|let\\)\\>\\|;;"
  "Regexp matching tblgen phrase delimitors.")
(defun tblgen-find-phrase-beginning ()
  "Find `real' phrase beginning and return point."
  (beginning-of-line)
  (tblgen-skip-blank-and-comments)
  (end-of-line)
  (tblgen-skip-to-end-of-phrase)
  (let ((old-point (point)))
    (tblgen-find-kwop tblgen-beginning-phrase-regexp)
    (while (and (> (point) (point-min)) (< (point) old-point)
		(or (not (looking-at tblgen-beginning-phrase-regexp))
		    (and (looking-at "\\<let\\>")
			 (tblgen-looking-at-expression-let))
		    (and (looking-at "\\<module\\>")
			 (tblgen-looking-at-false-module))
		    (and (looking-at "\\<\\(sig\\|struct\\)\\>")
			 (tblgen-looking-at-false-sig-struct))
		    (and (looking-at "\\<type\\>")
			 (tblgen-looking-at-false-type))))
      (if (looking-at "\\<end\\>")
	  (tblgen-find-match)
	(if (not (bolp)) (tblgen-backward-char))
	(setq old-point (point))
	(tblgen-find-kwop tblgen-beginning-phrase-regexp)))
    (if (tblgen-at-phrase-break-p)
	(progn (end-of-line) (tblgen-skip-blank-and-comments)))
    (back-to-indentation)
    (point)))

(defun tblgen-search-forward-end-iter (begin current)
  (let ((found) (move t))
    (while (and move (> (point) current))
      (if (re-search-forward "\\<end\\>" (point-max) t)
	  (when (not (tblgen-in-literal-or-comment-p))
	    (let ((kwop) (iter))
	      (save-excursion
		(tblgen-backward-char 3)
		(setq kwop (tblgen-find-match))
		(cond
		 ((looking-at "\\<\\(object\\)\\>")
		  (tblgen-find-phrase-beginning))
		 ((and (looking-at "\\<\\(struct\\|sig\\)\\>")
		       (tblgen-looking-at-false-sig-struct))
		  (tblgen-find-phrase-beginning)))
		(if (> (point) begin)
		    (setq iter t)))
	      (cond
	       ((or iter
		    (and
		     (string= kwop "sig")
		     (looking-at "[ \t\n]*\\(\\<with\\>[ \t\n]*\\<type\\>\\|=\\)")))
		(if (> (point) current)
		    (setq current (point))
		  (setq found nil move nil)))
	       (t (setq found t move nil)))))
	(setq found nil move nil)))
    found))

(defun tblgen-search-forward-end ()
  (tblgen-search-forward-end-iter (point) -1))

(defconst tblgen-inside-block-opening "\\<\\(struct\\|sig\\|object\\)\\>")
(defconst tblgen-inside-block-opening-full
  (concat tblgen-inside-block-opening "\\|\\<\\(module\\|class\\)\\>"))
(defconst tblgen-inside-block-regexp
  (concat tblgen-matching-keyword-regexp "\\|" tblgen-inside-block-opening))
(defun tblgen-inside-block-find-kwop ()
  (let ((kwop (tblgen-find-kwop tblgen-inside-block-regexp
				"\\<\\(and\\|end\\)\\>")))
    (if (string= kwop "and") (setq kwop (tblgen-find-and-match)))
    (if (string= kwop "with") (setq kwop nil))
    (if (string= kwop "end")
	(progn
	  (tblgen-find-match)
	  (tblgen-find-kwop tblgen-inside-block-regexp)
	  (tblgen-inside-block-find-kwop))
      kwop)))

(defun tblgen-inside-block-p ()
  (if (tblgen-in-literal-or-comment-p)
      (tblgen-beginning-of-literal-or-comment))
  (let ((begin) (end) (and-end) (and-iter t) (kwop t))
    (save-excursion
      (if (looking-at "\\<and\\>")
	  (tblgen-find-and-match))
      (setq begin (point))
      (if (or (and (looking-at "\\<class\\>")
		   (save-excursion
		     (re-search-forward "\\<object\\>"
					(point-max) t)
		     (while (and (tblgen-in-literal-or-comment-p)
                                 (re-search-forward "\\<object\\>"
                                                    (point-max) t)))
		     (tblgen-find-phrase-beginning)
		     (> (point) begin)))
	      (and (looking-at "\\<module\\>")
		   (save-excursion
		     (re-search-forward "\\<\\(sig\\|struct\\)\\>"
					(point-max) t)
		     (while (and (tblgen-in-literal-or-comment-p)
                                 (re-search-forward "\\<\\(sig\\|struct\\)\\>"
                                                    (point-max) t)))
		     (tblgen-find-phrase-beginning)
		     (> (point) begin)))) ()
	(if (not (looking-at tblgen-inside-block-opening-full))
	    (setq kwop (tblgen-inside-block-find-kwop)))
	(if (not kwop) ()
	  (setq begin (point))
	  (if (not (tblgen-search-forward-end)) ()
	    (tblgen-backward-char 3)
	    (if (not (looking-at "\\<end\\>")) ()
	      (tblgen-forward-char 3)
	      (setq end (point))
	      (setq and-end (point))
	      (tblgen-skip-blank-and-comments)
	      (while (and and-iter (looking-at "\\<and\\>"))
		(setq and-end (point))
		(if (not (tblgen-search-forward-end)) ()
		  (tblgen-backward-char 3)
		  (if (not (looking-at "\\<end\\>")) ()
		    (tblgen-forward-char 3)
		    (setq and-end (point))
		    (tblgen-skip-blank-and-comments)))
		(if (<= (point) and-end)
		    (setq and-iter nil)))
	      (list begin end and-end))))))))

(defun tblgen-move-inside-block-opening ()
  "Go to the beginning of the enclosing module or class.

Notice that white-lines (or comments) located immediately before a
module/class are considered enclosed in this module/class."
  (interactive)
  (let* ((old-point (point))
	 (kwop (tblgen-inside-block-find-kwop)))
    (if (not kwop)
	(goto-char old-point))
    (tblgen-find-phrase-beginning)))

(defun tblgen-discover-phrase (&optional quiet)
  (end-of-line)
  (let ((end (point)) (case-fold-search nil))
    (tblgen-modify-syntax)
    (tblgen-find-phrase-beginning)
    (if (> (point) end) (setq end (point)))
    (save-excursion
      (let ((begin (point)) (cpt 0) (lines-left 0) (stop)
	    (inside-block (tblgen-inside-block-p))
	    (looking-block (looking-at tblgen-inside-block-opening-full)))
	(if (and looking-block inside-block)
	    (progn
	      (setq begin (nth 0 inside-block))
	      (setq end (nth 2 inside-block))
	      (goto-char end))
	  (if inside-block
	      (progn
		(setq stop (save-excursion (goto-char (nth 1 inside-block))
					   (beginning-of-line) (point)))
		(if (< stop end) (setq stop (point-max))))
	    (setq stop (point-max)))
	  (save-restriction
	    (goto-char end)
	    (while (and (= lines-left 0)
			(or (not inside-block) (< (point) stop))
			(<= (save-excursion
			      (tblgen-find-phrase-beginning)) end))
	      (if (not quiet)
		  (progn
		    (setq cpt (1+ cpt))
		    (if (= 8 cpt)
			(message "Looking for enclosing phrase..."))))
	      (setq end (point))
	      (tblgen-skip-to-end-of-phrase)
	      (beginning-of-line)
	      (narrow-to-region (point) (point-max))
	      (goto-char end)
	      (setq lines-left (forward-line 1)))))
	(if (>= cpt 8) (message "Looking for enclosing phrase... done."))
	(save-excursion (tblgen-skip-blank-and-comments) (setq end (point)))
	(tblgen-skip-back-blank-and-comments)
	(tblgen-restore-syntax)
	(list begin (point) end)))))

(defun tblgen-mark-phrase ()
  "Put mark at end of this Caml phrase, point at beginning.
The Caml phrase is the phrase just before the point."
  (interactive)
  (let ((pair (tblgen-discover-phrase)))
    (goto-char (nth 1 pair)) (push-mark (nth 0 pair) t t)))

(defun tblgen-next-phrase (&optional quiet)
  "Skip to the beginning of the next phrase."
  (interactive "i")
  (goto-char (save-excursion (nth 2 (tblgen-discover-phrase quiet))))
  (if (looking-at "\\<end\\>")
      (tblgen-next-phrase quiet))
  (if (looking-at ";;")
      (progn
	(forward-char 2)
	(tblgen-skip-blank-and-comments))))

(defun tblgen-previous-phrase ()
  "Skip to the beginning of the previous phrase."
  (interactive)
  (beginning-of-line)
  (tblgen-skip-to-end-of-phrase)
  (tblgen-discover-phrase))

(defun tblgen-indent-phrase ()
  "Depending of the context: justify and indent a comment,
or indent all lines in the current phrase."
  (interactive)
  (save-excursion
    (back-to-indentation)
    (if (tblgen-in-comment-p)
	(let* ((cobpoint (save-excursion
			   (tblgen-beginning-of-literal-or-comment)
			   (point)))
	       (begpoint (save-excursion
			   (while (and (> (point) cobpoint)
				       (tblgen-in-comment-p)
				       (not (looking-at "^[ \t]*$")))
			     (forward-line -1))
			   (max cobpoint (point))))
	       (coepoint (save-excursion
			   (while (tblgen-in-comment-p)
			     (re-search-forward "\\*)"))
			   (point)))
	       (endpoint (save-excursion
			   (re-search-forward "^[ \t]*$" coepoint 'end)
			   (beginning-of-line)
			   (forward-line 1)
			   (point)))
	       (leading-star (tblgen-leading-star-p)))
	  (goto-char begpoint)
	  (while (and leading-star
		      (< (point) endpoint)
		      (not (looking-at "^[ \t]*$")))
	    (forward-line 1)
	    (back-to-indentation)
	    (if (looking-at "\\*\\**\\([^)]\\|$\\)")
		(progn
		  (delete-char 1)
		  (setq endpoint (1- endpoint)))))
	  (goto-char (min (point) endpoint))
	  (fill-region begpoint endpoint)
	  (re-search-forward "\\*)")
	  (setq endpoint (point))
	  (if leading-star
	      (progn
		(goto-char begpoint)
		(forward-line 1)
		(if (< (point) endpoint)
		    (tblgen-auto-fill-insert-leading-star t))))
	  (indent-region begpoint endpoint nil))
      (let ((pair (tblgen-discover-phrase)))
	(indent-region (nth 0 pair) (nth 1 pair) nil)))))

(defun tblgen-find-alternate-file ()
  "Switch Implementation/Interface."
  (interactive)
  (let ((name (buffer-file-name)))
    (if (string-match "\\`\\(.*\\)\\.ml\\(i\\)?\\'" name)
	(find-file (concat (tblgen-match-string 1 name)
			   (if (match-beginning 2) ".ml" ".mli"))))))

(defun tblgen-insert-class-form ()
  "Insert a nicely formatted class-end form, leaving a mark after end."
  (interactive "*")
  (let ((prec (preceding-char))) 
    (if (and prec (not (char-equal ?\  (char-syntax prec))))
        (insert " ")))
  (let ((old (point)))
    (insert "class  = object (self)\ninherit  as super\nend;;\n")
    (end-of-line)
    (indent-region old (point) nil)
    (indent-according-to-mode)
    (push-mark)
    (forward-line -2)
    (indent-according-to-mode)))

(defun tblgen-insert-begin-form ()
  "Insert a nicely formatted begin-end form, leaving a mark after end."
  (interactive "*")
  (let ((prec (preceding-char)))
    (if (and prec (not (char-equal ?\  (char-syntax prec))))
	(insert " ")))
  (let ((old (point)))
    (insert "begin\n\nend\n")
    (end-of-line)
    (indent-region old (point) nil)
    (push-mark)
    (forward-line -2)
    (indent-according-to-mode)))

(defun tblgen-insert-for-form ()
  "Insert a nicely formatted for-to-done form, leaving a mark after done."
  (interactive "*")
  (let ((prec (preceding-char)))
    (if (and prec (not (char-equal ?\  (char-syntax prec))))
	(insert " ")))
  (let ((old (point)))
    (insert "for  do\n\ndone\n")
    (end-of-line)
    (indent-region old (point) nil)
    (push-mark)
    (forward-line -2)
    (indent-according-to-mode)
    (beginning-of-line 1)
    (backward-char 4)))

(defun tblgen-insert-while-form ()
  "Insert a nicely formatted for-to-done form, leaving a mark after done."
  (interactive "*")
  (let ((prec (preceding-char)))
    (if (and prec (not (char-equal ?\  (char-syntax prec))))
	(insert " ")))
  (let ((old (point)))
    (insert "while  do\n\ndone\n")
    (end-of-line)
    (indent-region old (point) nil)
    (push-mark)
    (forward-line -2)
    (indent-according-to-mode)
    (beginning-of-line 1)
    (backward-char 4)))

(defun tblgen-insert-if-form ()
  "Insert a nicely formatted if-then-else form, leaving a mark after else."
  (interactive "*")
  (let ((prec (preceding-char)))
    (if (and prec (not (char-equal ?\  (char-syntax prec))))
	(insert " ")))
  (let ((old (point)))
    (insert "if\n\nthen\n\nelse\n")
    (end-of-line)
    (indent-region old (point) nil)
    (indent-according-to-mode)
    (push-mark)
    (forward-line -2)
    (indent-according-to-mode)
    (forward-line -2)
    (indent-according-to-mode)))

(defun tblgen-insert-match-form ()
  "Insert a nicely formatted math-with form, leaving a mark after with."
  (interactive "*")
  (let ((prec (preceding-char)))
    (if (and prec (not (char-equal ?\  (char-syntax prec))))
	(insert " ")))
  (let ((old (point)))
    (insert "match\n\nwith\n")
    (end-of-line)
    (indent-region old (point) nil)
    (indent-according-to-mode)
    (push-mark)
    (forward-line -2)
    (indent-according-to-mode)))

(defun tblgen-insert-let-form ()
  "Insert a nicely formatted let-in form, leaving a mark after in."
  (interactive "*")
  (let ((prec (preceding-char)))
    (if (and prec (not (char-equal ?\  (char-syntax prec))))
	(insert " ")))
  (let ((old (point)))
    (insert "let  in\n")
    (end-of-line)
    (indent-region old (point) nil)
    (indent-according-to-mode)
    (push-mark)
    (beginning-of-line)
    (backward-char 4)
    (indent-according-to-mode)))

(defun tblgen-insert-try-form ()
  "Insert a nicely formatted try-with form, leaving a mark after with."
  (interactive "*")
  (let ((prec (preceding-char)))
    (if (and prec (not (char-equal ?\  (char-syntax prec))))
	(insert " ")))
  (let ((old (point)))
    (insert "try\n\nwith\n")
    (end-of-line)
    (indent-region old (point) nil)
    (indent-according-to-mode)
    (push-mark)
    (forward-line -2)
    (indent-according-to-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                            Tblgen interactive mode

;; Augment Tblgen mode with a Caml toplevel.

(require 'comint)

(defvar tblgen-interactive-mode-map
  (let ((map (copy-keymap comint-mode-map)))
    (define-key map "|" 'tblgen-electric)
    (define-key map ")" 'tblgen-electric-rp)
    (define-key map "}" 'tblgen-electric-rc)
    (define-key map "]" 'tblgen-electric-rb)
    (define-key map "\C-c\C-i" 'tblgen-interrupt-caml)
    (define-key map "\C-c\C-k" 'tblgen-kill-caml)
    (define-key map "\C-c`" 'tblgen-interactive-next-error-toplevel)
    (define-key map "\C-c?" 'tblgen-interactive-next-error-toplevel)
    (define-key map "\C-m" 'tblgen-interactive-send-input)
    (define-key map "\C-j" 'tblgen-interactive-send-input-or-indent)
    (define-key map "\M-\C-m" 'tblgen-interactive-send-input-end-of-phrase)
    (define-key map [kp-enter] 'tblgen-interactive-send-input-end-of-phrase)
    map))

(defconst tblgen-interactive-buffer-name "*caml-toplevel*")

(defconst tblgen-interactive-toplevel-error-regexp
  "[ \t]*Characters \\([0-9]+\\)-\\([0-9]+\\):"
  "Regexp matching the char numbers in ocaml toplevel's error messages.")
(defvar tblgen-interactive-last-phrase-pos-in-source 0)
(defvar tblgen-interactive-last-phrase-pos-in-toplevel 0)

(defun tblgen-interactive-filter (text)
  (when (eq major-mode 'tblgen-interactive-mode)
    (save-excursion
      (when (>= comint-last-input-end comint-last-input-start)
	(if tblgen-interactive-read-only-input
	    (add-text-properties
	     comint-last-input-start comint-last-input-end
	     (list 'read-only t)))
	(if (and font-lock-mode tblgen-interactive-input-font-lock)
	    (progn
	      (font-lock-fontify-region comint-last-input-start
					comint-last-input-end)
	      (if (featurep 'sym-lock)
		  (sym-lock-make-symbols-atomic comint-last-input-start
						comint-last-input-end))))
	(if tblgen-interactive-output-font-lock
	    (save-excursion
	      (goto-char (point-max))
	      (re-search-backward comint-prompt-regexp
				  comint-last-input-end t)
	      (add-text-properties
	       comint-last-input-end (point)
	       '(face tblgen-font-lock-interactive-output-face))))
	(if tblgen-interactive-error-font-lock
	    (save-excursion
	      (goto-char comint-last-input-end)
	      (while (re-search-forward tblgen-interactive-error-regexp () t)
		(let ((matchbeg (match-beginning 1))
		      (matchend (match-end 1)))
		  (save-excursion
		    (goto-char matchbeg)
		    (put-text-property
		     matchbeg matchend
		     'face 'tblgen-font-lock-interactive-error-face)
		    (if (looking-at tblgen-interactive-toplevel-error-regexp)
			(let ((beg (string-to-number (tblgen-match-string 1)))
			      (end (string-to-number (tblgen-match-string 2))))
			  (put-text-property
			   (+ comint-last-input-start beg)
			   (+ comint-last-input-start end)
			   'face 'tblgen-font-lock-error-face)
			  )))))))))))

(define-derived-mode tblgen-interactive-mode comint-mode "Tblgen-Interactive"
  "Major mode for interacting with a Caml process.
Runs a Caml toplevel as a subprocess of Emacs, with I/O through an
Emacs buffer. A history of input phrases is maintained. Phrases can
be sent from another buffer in Caml mode.

Special keys for Tblgen interactive mode:\\{tblgen-interactive-mode-map}"
  (tblgen-install-font-lock t)
  (if (or tblgen-interactive-input-font-lock
	  tblgen-interactive-output-font-lock
	  tblgen-interactive-error-font-lock)
      (font-lock-mode 1))
  (add-hook 'comint-output-filter-functions 'tblgen-interactive-filter)
  (if (not (boundp 'after-change-functions)) ()
    (make-local-hook 'after-change-functions)
    (remove-hook 'after-change-functions 'font-lock-after-change-function t))
  (if (not (boundp 'pre-idle-hook)) ()
    (make-local-hook 'pre-idle-hook)
    (remove-hook 'pre-idle-hook 'font-lock-pre-idle-hook t))
  (setq comint-prompt-regexp "^#  *")
  (setq comint-process-echoes nil)
  (setq comint-get-old-input 'tblgen-interactive-get-old-input)
  (setq comint-scroll-to-bottom-on-output t)
  (set-syntax-table tblgen-mode-syntax-table)
  (setq local-abbrev-table tblgen-mode-abbrev-table)

  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'tblgen-indent-command)

  (easy-menu-add tblgen-interactive-mode-menu)
  (tblgen-update-options-menu))

(defun tblgen-run-caml ()
  "Run a Caml toplevel process. I/O via buffer `*caml-toplevel*'."
  (interactive)
  (tblgen-run-process-if-needed)
  (when tblgen-display-buffer-on-eval
    (display-buffer tblgen-interactive-buffer-name)))

(defun tblgen-run-process-if-needed (&optional cmd)
  "Run a Caml toplevel process if needed, with an optional command name.
I/O via buffer `*caml-toplevel*'."
  (if cmd
      (setq tblgen-interactive-program cmd)
    (if (not (comint-check-proc tblgen-interactive-buffer-name))
	(setq tblgen-interactive-program
	      (read-shell-command "Caml toplevel to run: "
				  tblgen-interactive-program))))
  (if (not (comint-check-proc tblgen-interactive-buffer-name))
      (let ((cmdlist (tblgen-args-to-list tblgen-interactive-program))
            (process-connection-type nil))
	(set-buffer (apply (function make-comint) "caml-toplevel"
			   (car cmdlist) nil (cdr cmdlist)))
	(tblgen-interactive-mode)
	(sleep-for 1))))

(defun tblgen-args-to-list (string)
  (let ((where (string-match "[ \t]" string)))
    (cond ((null where) (list string))
	  ((not (= where 0))
	   (cons (substring string 0 where)
		 (tblgen-args-to-list (substring string (+ 1 where)
						 (length string)))))
	  (t (let ((pos (string-match "[^ \t]" string)))
	       (if (null pos)
		   nil
		 (tblgen-args-to-list (substring string pos
						 (length string)))))))))

(defun tblgen-interactive-get-old-input ()
  (save-excursion
    (let ((end (point)))
      (re-search-backward comint-prompt-regexp (point-min) t)
      (if (looking-at comint-prompt-regexp)
	  (re-search-forward comint-prompt-regexp))
      (buffer-substring-no-properties (point) end))))

(defun tblgen-interactive-end-of-phrase ()
  (save-excursion
    (end-of-line)
    (tblgen-find-meaningful-word)
    (tblgen-find-meaningful-word)
    (looking-at ";;")))

(defun tblgen-interactive-send-input-end-of-phrase ()
  (interactive)
  (goto-char (point-max))
  (if (not (tblgen-interactive-end-of-phrase))
      (insert ";;"))
  (comint-send-input))

(defconst tblgen-interactive-send-warning
  "Note: toplevel processing requires a terminating `;;'")

(defun tblgen-interactive-send-input ()
  "Process if the current line ends with `;;' then send the
current phrase else insert a newline."
  (interactive)
  (if (tblgen-interactive-end-of-phrase)
      (progn
	(comint-send-input)
	(goto-char (point-max)))
    (insert "\n")
    (message tblgen-interactive-send-warning)))

(defun tblgen-interactive-send-input-or-indent ()
  "Process if the current line ends with `;;' then send the
current phrase else insert a newline and indent."
  (interactive)
  (if (tblgen-interactive-end-of-phrase)
      (progn
	(goto-char (point-max))
	(comint-send-input))
    (insert "\n")
    (indent-according-to-mode)
    (message tblgen-interactive-send-warning)))

(defun tblgen-eval-region (start end)
  "Eval the current region in the Caml toplevel."
  (interactive "r")
  (save-excursion (tblgen-run-process-if-needed))
  (comint-preinput-scroll-to-bottom)
  (setq tblgen-interactive-last-phrase-pos-in-source start)
  (save-excursion
    (goto-char start)
    (tblgen-skip-blank-and-comments)
    (setq start (point))
    (goto-char end)
    (tblgen-skip-to-end-of-phrase)
    (setq end (point))
    (let ((text (buffer-substring-no-properties start end)))
      (goto-char end)
      (if (string= text "")
	  (message "Cannot send empty commands to Caml toplevel!")
	(set-buffer tblgen-interactive-buffer-name)
	(goto-char (point-max))
	(setq tblgen-interactive-last-phrase-pos-in-toplevel (point))
	(comint-send-string tblgen-interactive-buffer-name
			    (concat text ";;"))
	(let ((pos (point)))
	  (comint-send-input)
	  (if tblgen-interactive-echo-phrase
	      (save-excursion
		(goto-char pos)
		(insert (concat text ";;")))))))
    (when tblgen-display-buffer-on-eval
      (display-buffer tblgen-interactive-buffer-name))))

(defun tblgen-narrow-to-phrase ()
  "Narrow the editting window to the surrounding Caml phrase (or block)."
  (interactive)
  (save-excursion
    (let ((pair (tblgen-discover-phrase)))
      (narrow-to-region (nth 0 pair) (nth 1 pair)))))

(defun tblgen-eval-phrase ()
  "Eval the surrounding Caml phrase (or block) in the Caml toplevel."
  (interactive)
  (let ((end))
    (save-excursion
      (let ((pair (tblgen-discover-phrase)))
	(setq end (nth 2 pair))
	(tblgen-eval-region (nth 0 pair) (nth 1 pair))))
    (if tblgen-skip-after-eval-phrase
	(goto-char end))))

(defun tblgen-eval-buffer ()
  "Send the buffer to the Tblgen Interactive process."
  (interactive)
  (tblgen-eval-region (point-min) (point-max)))

(defun tblgen-interactive-next-error-source ()
  (interactive)
  (let ((error-pos) (beg 0) (end 0))
    (save-excursion
      (set-buffer tblgen-interactive-buffer-name)
      (goto-char tblgen-interactive-last-phrase-pos-in-toplevel)
      (setq error-pos
	    (re-search-forward tblgen-interactive-toplevel-error-regexp
			       (point-max) t))
      (if error-pos
	  (progn
	    (setq beg (string-to-number (tblgen-match-string 1))
		  end (string-to-number (tblgen-match-string 2))))))
    (if (not error-pos)
	(message "No syntax or typing error in last phrase.")
      (setq beg (+ tblgen-interactive-last-phrase-pos-in-source beg)
	    end (+ tblgen-interactive-last-phrase-pos-in-source end))
      (goto-char beg)
      (put-text-property beg end 'face 'tblgen-font-lock-error-face))))

(defun tblgen-interactive-next-error-toplevel ()
  (interactive)
  (let ((error-pos) (beg 0) (end 0))
    (save-excursion
      (goto-char tblgen-interactive-last-phrase-pos-in-toplevel)
      (setq error-pos
	    (re-search-forward tblgen-interactive-toplevel-error-regexp
			       (point-max) t))
      (if error-pos
	  (setq beg (string-to-number (tblgen-match-string 1))
		end (string-to-number (tblgen-match-string 2)))))
    (if (not error-pos)
	(message "No syntax or typing error in last phrase.")
      (setq beg (+ tblgen-interactive-last-phrase-pos-in-toplevel beg)
	    end (+ tblgen-interactive-last-phrase-pos-in-toplevel end))
      (put-text-property beg end 'face 'tblgen-font-lock-error-face)
      (goto-char beg))))

(defun tblgen-interrupt-caml ()
  (interactive)
  (if (comint-check-proc tblgen-interactive-buffer-name)
      (save-excursion
	(set-buffer tblgen-interactive-buffer-name)
	(comint-interrupt-subjob))))

(defun tblgen-kill-caml ()
  (interactive)
  (if (comint-check-proc tblgen-interactive-buffer-name)
      (save-excursion
	(set-buffer tblgen-interactive-buffer-name)
	(comint-kill-subjob))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                               Menu support

(defun tblgen-about () (interactive)
  (describe-variable 'tblgen-mode-version))
(defun tblgen-help () (interactive)
  (describe-function 'tblgen-mode))
(defun tblgen-interactive-help () (interactive)
  (describe-function 'tblgen-interactive-mode))

(defvar tblgen-definitions-menu-last-buffer nil)
(defvar tblgen-definitions-keymaps nil)

(defun tblgen-build-menu ()
  (easy-menu-define
   tblgen-mode-menu (list tblgen-mode-map)
   "Tblgen Mode Menu."
   '("Tblgen"
     ("Interactive Mode"
      ["Run Caml Toplevel" tblgen-run-caml t]
      ["Interrupt Caml Toplevel" tblgen-interrupt-caml
       :active (comint-check-proc tblgen-interactive-buffer-name)]
      ["Kill Caml Toplevel" tblgen-kill-caml
       :active (comint-check-proc tblgen-interactive-buffer-name)]
      ["Evaluate Region" tblgen-eval-region
       ;; Region-active-p for XEmacs and mark-active for Emacs
       :active (if (fboundp 'region-active-p) (region-active-p) mark-active)]
      ["Evaluate Phrase" tblgen-eval-phrase t]
      ["Evaluate Buffer" tblgen-eval-buffer t])
     ("Caml Forms"
      ["try .. with .." tblgen-insert-try-form t]
      ["match .. with .." tblgen-insert-match-form t]
      ["let .. in .." tblgen-insert-let-form t]
      ["if .. then .. else .." tblgen-insert-if-form t]
      ["while .. do .. done" tblgen-insert-while-form t]
      ["for .. do .. done" tblgen-insert-for-form t]
      ["begin .. end" tblgen-insert-begin-form t])
     ["Switch .ml/.mli" tblgen-find-alternate-file t]
     "---"
     ["Compile..." compile t]
     ["Reference Manual..." tblgen-browse-manual t]
     ["Caml Library..." tblgen-browse-library t]
     ("Definitions"
      ["Scan..." tblgen-list-definitions t])
     "---"
     [ "Show type at point" caml-types-show-type
       tblgen-with-caml-mode-p]
     "---"
     [ "Complete identifier" caml-complete
       tblgen-with-caml-mode-p]
     [ "Help for identifier" caml-help
       tblgen-with-caml-mode-p]
     [ "Add path for documentation" ocaml-add-path
       tblgen-with-caml-mode-p]
     [ "Open module for documentation" ocaml-open-module
       tblgen-with-caml-mode-p]
     [ "Close module for documentation" ocaml-close-module
       tblgen-with-caml-mode-p]
     "---"
     ["Customize Tblgen Mode..." (customize-group 'tblgen) t]
     ("Tblgen Options" ["Dummy" nil t])
     ("Tblgen Interactive Options" ["Dummy" nil t])
     "---"
     ["About" tblgen-about t]
     ["Help" tblgen-help t]))
  (easy-menu-add tblgen-mode-menu)
  (tblgen-update-options-menu)
  ;; Save and update definitions menu
  (if tblgen-with-xemacs
      (add-hook 'activate-menubar-hook 'tblgen-update-definitions-menu)
    (if (not (functionp 'easy-menu-create-keymaps)) ()
      ;; Patch for Emacs
      (add-hook 'menu-bar-update-hook
		'tblgen-with-emacs-update-definitions-menu)
      (make-local-variable 'tblgen-definitions-keymaps)
      (setq tblgen-definitions-keymaps
	    (cdr (easy-menu-create-keymaps
		  "Definitions" tblgen-definitions-menu)))
      (setq tblgen-definitions-menu-last-buffer nil))))

(easy-menu-define
  tblgen-interactive-mode-menu tblgen-interactive-mode-map
  "Tblgen Interactive Mode Menu."
  '("Tblgen"
    ("Interactive Mode"
     ["Run Caml Toplevel" tblgen-run-caml t]
     ["Interrupt Caml Toplevel" tblgen-interrupt-caml
      :active (comint-check-proc tblgen-interactive-buffer-name)]
     ["Kill Caml Toplevel" tblgen-kill-caml
      :active (comint-check-proc tblgen-interactive-buffer-name)]
     ["Evaluate Region" tblgen-eval-region :active (region-active-p)]
     ["Evaluate Phrase" tblgen-eval-phrase t]
     ["Evaluate Buffer" tblgen-eval-buffer t])
    "---"
    ["Customize Tblgen Mode..." (customize-group 'tblgen) t]
    ("Tblgen Options" ["Dummy" nil t])
    ("Tblgen Interactive Options" ["Dummy" nil t])
    "---"
    ["About" tblgen-about t]
    ["Help" tblgen-interactive-help t]))

(defun tblgen-update-definitions-menu ()
  (if (eq major-mode 'tblgen-mode)
      (easy-menu-change
       '("Tblgen") "Definitions"
       tblgen-definitions-menu)))

(defun tblgen-with-emacs-update-definitions-menu ()
  (if (current-local-map)
      (let ((keymap
	     (lookup-key (current-local-map) [menu-bar Tblgen Definitions])))
	(if (and
	     (keymapp keymap)
	     (not (eq tblgen-definitions-menu-last-buffer (current-buffer))))
	    (setcdr keymap tblgen-definitions-keymaps)
	  (setq tblgen-definitions-menu-last-buffer (current-buffer))))))

(defun tblgen-toggle-option (symbol)
  (interactive)
  (set symbol (not (symbol-value symbol)))
  (if (eq 'tblgen-use-abbrev-mode symbol)
      (abbrev-mode tblgen-use-abbrev-mode)) ; toggle abbrev minor mode
  (if tblgen-with-xemacs nil (tblgen-update-options-menu)))

(defun tblgen-update-options-menu ()
  (easy-menu-change
   '("Tblgen") "Tblgen Options"
   (mapcar (lambda (pair)
	     (if (consp pair)
		 (vector (car pair)
			 (list 'tblgen-toggle-option (cdr pair))
			 ':style 'toggle
			 ':selected (nth 1 (cdr pair))
			 ':active t)
	       pair)) tblgen-options-list))
  (easy-menu-change
   '("Tblgen") "Tblgen Interactive Options"
   (mapcar (lambda (pair)
	     (if (consp pair)
		 (vector (car pair)
			 (list 'tblgen-toggle-option (cdr pair))
			 ':style 'toggle
			 ':selected (nth 1 (cdr pair))
			 ':active t)
	       pair)) tblgen-interactive-options-list)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             Browse Manual

;; From M. Quercia

(defun tblgen-browse-manual ()
  "*Browse Caml reference manual."
  (interactive)
  (setq tblgen-manual-url (read-from-minibuffer "URL: " tblgen-manual-url))
  (funcall tblgen-browser tblgen-manual-url))

(defun tblgen-xemacs-w3-manual (url)
  "*Browse Caml reference manual."
  (w3-fetch-other-frame url))

(defun tblgen-netscape-manual (url)
  "*Browse Caml reference manual."
  (start-process-shell-command
   "netscape" nil
   (concat "netscape -remote 'openURL ("
	   url ", newwindow)' || netscape " url)))

(defun tblgen-mmm-manual (url)
  "*Browse Caml reference manual."
  (start-process-shell-command
   "mmm" nil
   (concat "mmm_remote " url " || mmm -external " url)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             Browse Library

;; From M. Quercia

(defun tblgen-browse-library()
  "Browse the Caml library."
  (interactive)
  (let ((buf-name "*caml-library*") (opoint)
	(dir (read-from-minibuffer "Library path: " tblgen-library-path)))
    (if (and (file-directory-p dir) (file-readable-p dir))
	(progn
	  (setq tblgen-library-path dir)
	  ;; List *.ml and *.mli files
	  (with-output-to-temp-buffer buf-name
	    (buffer-disable-undo standard-output)
	    (save-excursion
	      (set-buffer buf-name)
	      (kill-all-local-variables)
	      (make-local-variable 'tblgen-library-path)
	      (setq tblgen-library-path dir)
	      ;; Help
	      (insert "Directory \"" dir "\".\n") 
	      (insert "Select a file with middle mouse button or RETURN.\n\n")
	      (insert "Interface files (.mli):\n\n")
	      (insert-directory (concat dir "/*.mli") "-C" t nil)
	      (insert "\n\nImplementation files (.ml):\n\n")
	      (insert-directory (concat dir "/*.ml") "-C" t nil)
	      ;; '.', '-' and '_' are now letters
	      (modify-syntax-entry ?. "w")
	      (modify-syntax-entry ?_ "w")
	      (modify-syntax-entry ?- "w")
	      ;; Every file name is now mouse-sensitive
	      (goto-char (point-min))
	      (while (< (point) (point-max))
		(re-search-forward "\\.ml.?\\>")
		(setq opoint (point))
		(re-search-backward "\\<" (point-min) 1)
		(put-text-property (point) opoint 'mouse-face 'highlight)
		(goto-char (+ 1 opoint)))
	      ;; Activate tblgen-library mode
	      (setq major-mode 'tblgen-library-mode)
	      (setq mode-name "tblgen-library")
	      (use-local-map tblgen-library-mode-map)
	      (setq buffer-read-only t)))))))
  
(defvar tblgen-library-mode-map
  (let ((map (make-keymap)))
    (suppress-keymap map)
    (define-key map [return] 'tblgen-library-find-file)
    (define-key map [mouse-2] 'tblgen-library-mouse-find-file)
    map))

(defun tblgen-library-find-file ()
  "Load the file whose name is near point."
  (interactive)
  (save-excursion
    (if (text-properties-at (point))
	(let (beg)
	  (re-search-backward "\\<") (setq beg (point))
	  (re-search-forward "\\>")
	  (find-file-read-only (concat tblgen-library-path "/"
				       (buffer-substring-no-properties
					beg (point))))))))

(defun tblgen-library-mouse-find-file (event)
  "Visit the file name you click on."
  (interactive "e")
  (let ((owindow (selected-window)))
    (mouse-set-point event)
    (tblgen-library-find-file)
    (select-window owindow)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             Definitions List

;; Designed from original code by M. Quercia

(defconst tblgen-definitions-regexp
  "\\<\\(and\\|val\\|type\\|module\\|class\\|exception\\|let\\)\\>"
  "Regexp matching definition phrases.")

(defconst tblgen-definitions-bind-skip-regexp
  (concat "\\<\\(rec\\|type\\|virtual\\)\\>\\|'[" tblgen-alpha "][0-9_'"
	  tblgen-alpha "]*\\|('.*)")
  "Regexp matching stuff to ignore after a binding keyword.")

(defvar tblgen-definitions-menu (list ["Scan..." tblgen-list-definitions t])
  "Initial content of the definitions menu.")
(make-variable-buffer-local 'tblgen-definitions-menu)

(defun tblgen-list-definitions ()
  "Parse the buffer and gather toplevel definitions for quick
jump via the definitions menu."
  (interactive)
  (message "Searching definitions...")
  (save-excursion
    (let ((cpt 0) (kw) (menu) (scan-error)
	  (value-list) (type-list) (module-list) (class-list) (misc-list))
      (goto-char (point-min))
      (tblgen-skip-blank-and-comments)
      (while (and (< (point) (point-max)) (not scan-error))
	(if (looking-at tblgen-definitions-regexp)
	    (progn
	      (setq kw (tblgen-match-string 0))
	      (if (string= kw "and")
		  (setq kw (save-match-data
			     (save-excursion (tblgen-find-and-match)))))
	      (if (or (string= kw "exception")
		      (string= kw "val")) (setq kw "let"))
	      ;; Skip optional elements
	      (goto-char (match-end 0))
	      (tblgen-skip-blank-and-comments)
	      (if (looking-at tblgen-definitions-bind-skip-regexp)
		  (goto-char (match-end 0)))
	      (tblgen-skip-blank-and-comments)
	      (if (looking-at
		   (concat "\\<[" tblgen-alpha "][0-9_'" tblgen-alpha "]*\\>"))
		  ;; Menu item : [name (goto-char ...) t]
		  (let* ((p (make-marker))
			 (ref (vector (tblgen-match-string 0)
				      (list 'tblgen-goto p) t)))
		    (setq cpt (1+ cpt))
		    (message (concat "Searching definitions... ("
				     (number-to-string cpt) ")"))
		    (set-marker p (point))
		    (cond
		     ((string= kw "let")
		      (setq value-list (cons ref value-list)))
		     ((string= kw "type")
		      (setq type-list (cons ref type-list)))
		     ((string= kw "module")
		      (setq module-list (cons ref module-list)))
		     ((string= kw "class")
		      (setq class-list (cons ref class-list)))
		     (t (setq misc-list (cons ref misc-list))))))))
	;; Skip to next phrase or next top-level `and'
	(tblgen-forward-char)
	(let ((old-point (point)) (last-and))
	  (tblgen-next-phrase t)
	  (setq last-and (point))
	  (if (< last-and old-point)
	      (setq scan-error t)
	    (save-excursion
	      (while (and (re-search-backward "\\<and\\>" old-point t)
			  (not (tblgen-in-literal-or-comment-p))
			  (save-excursion (tblgen-find-and-match)
					  (>= old-point (point))))
		(setq last-and (point)))))
	  (goto-char last-and)))
      (if scan-error
	  (message "Parse error when scanning definitions: line %s!"
		   (if tblgen-with-xemacs
		       (line-number)
		     (1+ (count-lines 1 (point)))))
	;; Sort and build lists
	(mapcar (lambda (pair)
		  (if (cdr pair)
		      (setq menu
			    (append (tblgen-split-long-list
				     (car pair) (tblgen-sort-definitions (cdr pair)))
				    menu))))
		(list (cons "Miscellaneous" misc-list)
		      (cons "Values" value-list)
		      (cons "Classes" class-list)
		      (cons "Types" type-list)
		      (cons "Modules" module-list)))
	;; Update definitions menu
	(setq tblgen-definitions-menu
	      (append menu (list "---"
				 ["Rescan..." tblgen-list-definitions t])))
	(if (or tblgen-with-xemacs
		(not (functionp 'easy-menu-create-keymaps))) ()
	  ;; Patch for Emacs
	  (setq tblgen-definitions-keymaps
		(cdr (easy-menu-create-keymaps 
		      "Definitions" tblgen-definitions-menu)))
	  (setq tblgen-definitions-menu-last-buffer nil))
	(message "Searching definitions... done"))))
  (tblgen-update-definitions-menu))

(defun tblgen-goto (pos)
  (goto-char pos)
  (recenter))

(defun tblgen-sort-definitions (list)
  (let* ((last "") (cpt 1)
	 (list (sort (nreverse list)
		     (lambda (p q) (string< (elt p 0) (elt q 0)))))
	 (tail list))
    (while tail
      (if (string= (elt (car tail) 0) last)
	  (progn
	    (setq cpt (1+ cpt))
	    (aset (car tail) 0 (format "%s (%d)" last cpt)))
	(setq cpt 1)
	(setq last (elt (car tail) 0)))
      (setq tail (cdr tail)))
    list))

;; Look for the (n-1)th or last element of a list
(defun tblgen-nth (n list)
  (if (or (<= n 1) (null list) (null (cdr list))) list
    (tblgen-nth (1- n) (cdr list))))
    
;; Split a definition list if it is too long
(defun tblgen-split-long-list (title list)
  (let ((tail (tblgen-nth tblgen-definitions-max-items list)))
    (if (or (null tail) (null (cdr tail)))
        ;; List not too long, cons the title
        (list (cons title list))
      ;; List too long, split and add initials to the title
      (let (lists)
        (while list
          (let ((beg (substring (elt (car list) 0) 0 1))
                (end (substring (elt (car tail) 0) 0 1)))
            (setq lists (cons
                         (cons (format "%s %s-%s" title beg end) list)
                         lists))
            (setq list (cdr tail))
            (setcdr tail nil)
            (setq tail (tblgen-nth tblgen-definitions-max-items list))))
        (nreverse lists)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                             Hooks and Exit

(condition-case nil
    (progn (require 'speedbar)
	   (speedbar-add-supported-extension
	    '(".ml" ".mli" ".mll" ".mly")))
  (error nil))

(defvar tblgen-load-hook nil
  "This hook is run when Tblgen is loaded in. It is a good place to put
key-bindings or hack Font-Lock keywords...")

(run-hooks 'tblgen-load-hook)

(provide 'tblgen)
;; For compatibility with caml support modes
;; you may also link caml.el to tblgen.el
(provide 'caml)

;;; tblgen.el ends here
