;;; actually-selected-window.el --- tell me dammit! -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Case Duckworth

;; Author: Case Duckworth <acdw@acdw.net>
;; Keywords: convenience

;;; Commentary:

;; Based on https://stackoverflow.com/questions/26061855/.  I'll quote Stefan's
;; answer here:

;; While the mode-line-format is evaluated for a given window, this window is
;; temporarily made the selected-window. In Emacs<=24.3 this was made only
;; halfway: selected-window was changed, but not frame-selected-window. This
;; meant that temporarily (frame-selected-window) was not equal to
;; (selected-window) and breaking this (normally) invariant was a source of
;; various corner case bugs. So we fixed it in 24.4, which means that your code
;; broke.

;; The actual code (and hook) I'm using is from ale, who answered just below.

;;; Code:

(defvar actually-selected-window nil
  "Which window is actually selected.")

(defun actually-selected-window-determine ()
  "Determine which window is actually selected.
Save the results in `actually-selected-window'."
  (when (not (minibuffer-selected-window))
    (setq actually-selected-window (selected-window))))

;;;###autoload
(define-minor-mode actually-selected-window-mode
  "A minor mode to actually know which window is selected.
While you can usually use `selected-window', you can't while
updating the mode-line because Emacs visits every window when
updating mode-lines."
  :init nil
  :lighter ""
  :keymap nil
  (if actually-selected-window-mode
      (add-hook 'post-command-hook #'actually-selected-window-determine)
    (remove-hook 'post-command-hook #'actually-selected-window-determine)))

(provide 'actually-selected-window)
;;; actually-selected-window.el ends here
