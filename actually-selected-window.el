;;; actually-selected-window.el --- What window is ACTUALLY selected? -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Case Duckworth

;; Author: Case Duckworth <acdw@acdw.net>
;; URL: https://github.com/duckwork/actually-selected-window.el
;; Package-Version: 1.0.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Based on https://stackoverflow.com/questions/26061855/.  I'll quote Stefan's
;; answer here:

;; While the mode-line-format is evaluated for a given window, this window is
;; temporarily made the selected-window.  In Emacs<=24.3 this was made only
;; halfway: selected-window was changed, but not frame-selected-window.  This
;; meant that temporarily (frame-selected-window) was not equal to
;; (selected-window) and breaking this (normally) invariant was a source of
;; various corner case bugs.  So we fixed it in 24.4, which means that your code
;; broke.

;; The actual code (and hook) I'm using is from  "ale", who answered just below.

;; UPDATE 2021-12-29: updated per this blog post, which has some other niceties:
;; https://occasionallycogent.com/custom_emacs_modeline/

;;; Code:

(defvar actually-selected-window nil
  "Which window is actually selected.")

(defun actually-selected-window-set (&rest _)
  "Determine which window is actually selected.
Save the results in `actually-selected-window' and update the
mode-line."
  (when (not (minibuffer-selected-window))
    (setq actually-selected-window (frame-selected-window))
    (force-mode-line-update)))

(defun actually-selected-window-set-across-frames ()
  "Call `actually-selected-window-set' on focused frames.
This function is intended to be added to
`after-focus-change-function', which see.

Note that this function doesn't do any debouncing of the frame
selection, so it might set `actually-selected-window' to the
selected window on a not-selected frame.  A fix would require
changing the type of `actually-selected-window' to a list of
selected windows on frames."
  (setq actually-selected-window nil)
  (mapc (lambda (frame)
          (when (eq t (frame-focus-state frame))
            (setq actually-selected-window (frame-selected-window))))
        (frames-on-display-list))
  (force-mode-line-update))

(defun actually-selected-window-unset (&rest _)
  "Unset the window selection and update the modeline.
This is useful when Emacs is unfocused, for example."
  (setq actually-selected-window nil)
  (force-mode-line-update))

;;;###autoload
(defun actually-selected-window-p (&optional window)
  "Determine whether WINDOW is actually selected.
WINDOW defaults to `selected-window'."
  (eq actually-selected-window (or window (selected-window))))

;;;###autoload
(define-minor-mode actually-selected-window-mode
  "A minor mode to actually know which window is selected.
While you can usually use `selected-window', you can't while
updating the mode-line because Emacs visits every window when
updating mode-lines."
  :lighter ""
  :keymap nil
  :global t
  (if actually-selected-window-mode
      (progn                            ; turn on
        (when (frame-focus-state)
          (actually-selected-window-set))
        (add-hook 'window-configuration-change-hook
                  #'actually-selected-window-set)
        (if (boundp 'after-focus-change-function)
            (add-function :after after-focus-change-function
                          #'actually-selected-window-set-across-frames)
          (add-hook 'focus-in-hook #'actually-selected-window-set)
          (add-hook 'focus-out-hook #'actually-selected-window-unset))
        (advice-add 'handle-switch-frame :after #'actually-selected-window-set)
        (advice-add 'select-window :after #'actually-selected-window-set))
    ;; turn off
    (remove-hook 'window-configuration-change-hook
                 #'actually-selected-window-set)
    (if (boundp 'after-focus-change-function)
        (remove-function after-focus-change-function
                         #'actually-selected-window-set-across-frames)
      (remove-hook 'focus-in-hook #'actually-selected-window-set)
      (remove-hook 'focus-out-hook #'actually-selected-window-unset))
    (advice-remove 'handle-switch-frame #'actually-selected-window-set)
    (advice-remove 'select-window #'actually-selected-window-set)
    (force-mode-line-update)))

(provide 'actually-selected-window)
;;; actually-selected-window.el ends here
