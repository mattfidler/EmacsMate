;;; init.el --- EmacsMate Initialization
;; 
;; Filename: init.el
;; Description: 
;; Author: Matthew L. Fidler
;; Maintainer: 
;; Created: Mon Sep 10 12:11:54 2012 (-0500)
;; Version: 
;; Last-Updated: Mon Sep 10 15:37:44 2012 (-0500)
;;           By: Matthew L. Fidler
;;     Update #: 10
;; URL: 
;; Keywords:
;; Compatibility: 
;; 
;; Features that might be required by this library:
;;
;;   Cannot open load file: init.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Commentary: 
;; 
;; 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Change Log:
;; 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Code:

(setq emacsmate-dir
      (file-name-directory
       (or load-file-name (buffer-file-name))))


(defconst emacsmate-start-time (float-time))

(defvar emacsmate-last-time emacsmate-start-time)

(defun emacsmate-m (txt)
  "* Emacsmate"
  (message "[Emacsmate] %s in %1f seconds, %1f seconds elapsed"
           txt
           (- (float-time) emacsmate-last-time)
           (- (float-time) emacsmate-start-time))
  (setq emacsmate-last-time (float-time)))

(emacsmate-m "Added lisp/src as magic source directory.")

(require 'org)
(emacsmate-m "Loaded latest Org-file")

;;(setq debug-on-error t)

(defcustom emacsmate-grace nil
  "Handle emacsmate errors with grace"
  :type 'boolean)


(defun emacsmate-load-org (file)
  "Loads Emacs Lisp source code blocks like `org-babel-load-file'.  However, byte-compiles the files as well as tangles them..."
  (flet ((age (file)
              (float-time
               (time-subtract (current-time)
                              (nth 5 (or (file-attributes (file-truename file))
                                         (file-attributes file)))))))
    (let* ((base-name (file-name-sans-extension file))
           (exported-file (concat base-name ".el"))
           (compiled-file (concat base-name ".elc")))
      (unless (and (file-exists-p exported-file)
                   (> (age file) (age exported-file)))
        (message "Trying to Tangle %s" file)
        (condition-case err
            (progn
              (org-babel-tangle-file file exported-file "emacs-lisp")
              (emacsmate-m (format "Tangled %s to %s"
                                   file exported-file)))
          (error (if emacsmate-grace
                     (message "Error Tangling %s" file)
                   (error "Error Tangling %s" file)))))
      (when (file-exists-p exported-file)
        (if (and (boundp 'auto-compile-on-load-mode) auto-compile-on-load-mode)
            (load exported-file)
          (if (and (file-exists-p compiled-file)
                   (> (age exported-file) (age compiled-file)))
              (progn
                (condition-case err
                    (load-file compiled-file)
                  (error (if emacsmate-grace
                             (message "Error Loading %s" compiled-file)
                           (error "Error Loading %s" compiled-file))))
                (emacsmate-m (format "Loaded %s" compiled-file)))
            (condition-case err
                (byte-compile-file exported-file t)
              (error (if emacsmate-grace
                         (message "Error Byte-compiling and loading %s" exported-file)
                       (error "Error Byte-compiling and loading %s" exported-file))))
            (emacsmate-m (format "Byte-compiled & loaded %s" exported-file))
            ;; Fallback and load source
            (if (file-exists-p compiled-file)
                (set-file-times compiled-file) ; Touch file.
              (condition-case err
                  (load-file exported-file)
                (error (if emacsmate-grace
                           (message "Error loading %s" exported-file)
                         (error "Error loading %s" exported-file))))
              (emacsmate-m (format "Loaded %s since byte-compile failed."
                                   exported-file)))))))))

;; load up emacsmate
(emacsmate-load-org
 (expand-file-name "EmacsMate.org" emacsmate-dir))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init.el ends here
