;; sar-modeline.el --- Code for my custom mode line -*- lexical-binding: t -*-

;; Copyright (C) 2024  Scott Runnels

;; Author: Scott Runnels <srunnels@gmail.com>
;; URL: https://github.com/srunnels/dotfiles
;; Version: 0.0.0
;; Package-Requires: ((emacs "30.1") (s "1.13.0"))


;;; Commentary:

;;; Code:

(require 's)

(defgroup sar-modeline nil
  "Custom modeline."
  :group 'mode-line)

(defgroup sar-modeline-faces nil
  "Faces for custom modeline."
  :group 'sar-modeline)

(defcustom sar-modeline-string-truncate-length 9
  "String length after which truncation should be done in small windows."
  :type 'natnum)

;;;; Faces
;; mode-line
;; mode-line-active
;; mode-line-buffer-id
;; mode-line-emphasis
;; mode-line-highlight
;; mode-line-inactive

;;;; Helper Functions

;;;;; VC Mode

(defface sar-modeline-vc-icon-face
  '((t :inherit comint-highlight-prompt))
  ".")

(defface sar-modeline-vc-face
  '((t :inherit comint-highlight-input :weight bold))
  ".")

(defvar sar-modeline-vc-icon-map
  '(("git" . ""))
  "A map for Version Control systems (e.g. Git).")

(defun sar-modeline--get-vc-icon (vc-name)
  "Return the cdr of the cons that maps to VC-NAME."
  (cdr (assoc (s-trim (downcase vc-name))
              sar-modeline-vc-icon-map)))

(defun sar-modeline--vc-mode-branch ()
  "Return an icon and branch name.

Splits the VC system off of 'vc-mode' and return propertized versions of
the system as an icon and the branch."
  (let* ((vc (s-split ":" (substring-no-properties vc-mode)))
         (vc-system (s-trim (car vc)))
         (vc-branch (cadr vc))
         (vc-icon (sar-modeline--get-vc-icon vc-system)))
    (concat (propertize vc-icon 'face 'sar-modeline-vc-icon-face)
            " "
            (propertize vc-branch 'face 'sar-modeline-vc-face))))

(defvar-local sar-modeline-vc-mode-branch
    '(:eval (when (and (mode-line-window-selected-p)
                       vc-mode)
              (sar-modeline--vc-mode-branch)))
  "Mode line construct to display an icon and text of VC branch name."
  )
(put 'sar-modeline-vc-mode-branch 'risky-local-variable t)

;;;;; Major Mode and Buffer Name Indication
(defvar sar-modeline-mode-icon-map
  '(("org-mode" . "")
    ("python-ts-mode" . "")
    ("fundamental-mode" . "λ")
    )
  "A map for major-mode to an icon for display.")

(defun sar-modeline-get-mode-icon (mode)
  "Return the cdr of the cons for MODE in from 'sar-modeline-mode-icon-map'."
  (cdr (assoc mode
              sar-modeline-mode-icon-map)))

;; Indicator template
;; (defun sar-modeline--foo)

;; (defvar-local sar-modeline-foo ()
;; ""
;; ())

;; (put 'sar-modeline-foo 'risky-local-variable t)

;; Persp mode
(defface sar-modeline-persp-mode-face
  '((t :inherit mode-line-buffer-id))
  ".")

(defun sar-modeline--persp-workspace ()
  "Return the current persp-mode workspace."
  (propertize (persp-current-name) ;; persp-last-persp-name
              'face
              'sar-modeline-persp-mode-face))

(defvar-local sar-modeline-persp-workspace
    '(:eval
      (when (mode-line-window-selected-p)
        (sar-modeline--persp-workspace)
        )))

(put 'sar-modeline-persp-workspace 'risky-local-variable t)

;; Flymake

(defun sar-modeline--flymake-indicator ()
  "Return the full flymake indicator strings.

Returns an indicator only on the active window."
  (when (and (derived-mode-p 'prog-mode)
             (mode-line-window-selected-p))
    (flymake--mode-line-counters)
    ))

(defvar-local sar-modeline-flymake-indicator
    '(:eval (sar-modeline--flymake-indicator)
  "Mode line construct to display an icon of the major mode."))

(put 'sar-modeline-flymake-indicator 'risky-local-variable t)

;; Major mode
(defface sar-modeline-buffer-name-modified-face
  '((t :inherit warning))
  ".")

(defface sar-modeline-buffer-name-face
  '((t :inherit mode-line-buffer-id))
  ".")

(defun sar-modeline--major-mode-indicator ()
  "Return the major mode as an icon and the buffer name.

Attempts to match an icon for a for the major mode or the
derived-mode before falling back to a default.  Appends the
buffer name."
  (let ((indicator (or (sar-modeline-get-mode-icon (symbol-name major-mode))
                       (cond
                         ((derived-mode-p 'text-mode) "§")
                         ((derived-mode-p 'prog-mode) "λ")
                         ((derived-mode-p 'comint-mode) ">_")
                         (t "◦")))))
    (concat (propertize indicator 'face 'shadow)
            " "
            (propertize " %b "
                        'face
                        (if (buffer-modified-p)
                            'sar-modeline-buffer-name-modified-face
                          'sar-modeline-buffer-name-face
                          )))))


(defvar-local sar-modeline-major-mode-indicator
    '(:eval (sar-modeline--major-mode-indicator))
  "Mode line construct to display an icon of the major mode.")

(put 'sar-modeline-major-mode-indicator 'risky-local-variable t)

;;;; Mode line format
(setq-default mode-line-format
              '(" "
                sar-modeline-major-mode-indicator
                " "
                sar-modeline-persp-workspace
                " "
                sar-modeline-vc-mode-branch
                " "
                org-clock-current-task
		" "
		eglot--mode-line-format
		" "
                sar-modeline-flymake-indicator
                ))

;; source https://protesilaos.com/codelog/2023-07-29-emacs-custom-modeline-tutorial/
(defun mode-line-window-selected-p ()
  "Return non-nil if we're updating the mode line for the selected window.
This function is meant to be called in `:eval' mode line
constructs to allow altering the look of the mode line depending
on whether the mode line belongs to the currently selected window
or not."
  (let ((window (selected-window)))
    (or (eq window (old-selected-window))
	(and (minibuffer-window-active-p (minibuffer-window))
	     (with-selected-window (minibuffer-window)
	       (eq window (minibuffer-selected-window)))))))

(provide 'sar-modeline)
;;; sar-modeline.el ends here
