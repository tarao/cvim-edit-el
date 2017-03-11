;;; cvim-edit.el --- cVim Edit Server on Emacs

;; Author: INA Lintaro <tarao.gnn at gmail.com>

;; This file is NOT part of GNU Emacs.

;;; License:
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'elnode)
(require 'json)

(defgroup cvim-edit nil
  "Edit browser textarea via cVim."
  :group 'applications)

(defcustom cvim-edit:server-port 8001
  "Port number of cVim edit server."
  :type 'integer
  :group 'cvim-edit)

(defcustom cvim-edit:buffer-name "*cvim*"
  "Name of the edit buffer."
  :type 'integer
  :group 'cvim-edit)

(defcustom cvim-edit:major-mode 'text-mode
  "Major mode of the edit buffer."
  :type 'function
  :group 'cvim-edit)

(defvar cvim-edit-connection nil)
(put 'cvim-edit-connection 'permanent-local t)
(make-variable-buffer-local 'cvim-edit-connection)

(defvar cvim-edit-content nil)
(put 'cvim-edit-content 'permanent-local t)
(make-variable-buffer-local 'cvim-edit-content)

(defun cvim-edit-kill-buffer ()
  (kill-buffer))

(defun cvim-edit-save-exit ()
  (cvim-edit-send-content)
  (cvim-edit:local-mode -1))

(defun cvim-edit-send-content ()
  (elnode-http-return cvim-edit-connection
                      (encode-coding-string (buffer-string) 'utf-8-unix)))

(defun cvim-edit-revert-content (&rest ignore)
  (delete-region (point-min) (point-max))
  (insert cvim-edit-content)
  (set-buffer-modified-p nil))

(define-minor-mode cvim-edit:local-mode
  "Minor mode for cVim edit buffer."
  :group 'cvim-edit
  (if cvim-edit:local-mode
      ;; on
      (let ((buffer-name (buffer-name)))
        (set-visited-file-name (locate-user-emacs-file ".cvim-edit") t)
        (rename-buffer buffer-name)
        (set (make-local-variable 'make-backup-files) nil)
        (add-hook 'after-revert-hook #'cvim-edit-restore-local-mode nil t)
        (add-hook 'after-change-major-mode-hook
                  #'cvim-edit-restore-local-mode nil t)
        (add-hook 'after-save-hook #'cvim-edit-kill-buffer nil t)
        (add-hook 'kill-buffer-hook #'cvim-edit-save-exit nil t)
        (set (make-local-variable 'revert-buffer-function)
             'cvim-edit-revert-content))
    ;; off
    (elnode-http-return cvim-edit-connection "")
    (remove-hook 'after-revert-hook #'cvim-edit-restore-local-mode t)
    (remove-hook 'after-change-major-mode-hook #'cvim-edit-restore-local-mode t)
    (remove-hook 'after-save-hook #'cvim-edit-kill-buffer t)
    (remove-hook 'kill-buffer-hook #'cvim-edit-save-exit t)
    (kill-local-variable 'make-backup-files)
    (kill-local-variable 'revert-buffer-function)
    (kill-local-variable 'cvim-edit-connection)
    (kill-local-variable 'cvim-edit-content)))

(defun cvim-edit-restore-local-mode ()
  (when (or (and (numberp cvim-edit:local-mode)
                 (<= cvim-edit:local-mode 0))
            (null cvim-edit:local-mode))
    (cvim-edit:local-mode 1)))
(put 'cvim-edit-restore-local-mode 'permanent-local-hook t)

(defun cvim-edit:server-handler (con)
  (let* ((buffer (generate-new-buffer cvim-edit:buffer-name))
         (json (with-current-buffer (process-buffer con)
                 (save-excursion
                   (goto-char (point-min))
                   (search-forward-regexp "\r\n\r\n")
                   (print (buffer-string))
                   (json-read-from-string
                    (buffer-substring-no-properties (point) (point-max))))))
         (content (cdr (assq 'data json)))
         (content (decode-coding-string
                   (string-make-unibyte content)
                   'utf-8-unix)))
    (with-current-buffer buffer
      (setq cvim-edit-connection con
            cvim-edit-content content)
      (when (fboundp cvim-edit:major-mode)
        (funcall cvim-edit:major-mode))
      (cvim-edit:local-mode 1)
      (cvim-edit-revert-content)
      (elnode-http-start con 200 '("Content-Type" . "text/plain")))
    (switch-to-buffer buffer)
    (raise-frame)
    (when (display-graphic-p)
      (x-focus-frame (selected-frame)))))

;;;###autoload
(defun cvim-edit:server-start ()
  "Start a cVim edit server."
  (elnode-start 'cvim-edit:server-handler
                :port cvim-edit:server-port
                :host "localhost"))

(provide 'cvim-edit)
;;; cvim-edit.el ends here
