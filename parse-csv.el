;;; parse-csv.el --- Parse strings with CSV fields into s-expressions

;; Copyright (C) 2002-2006 Edward Marco Baringer
;; All rights reserved.
;;
;; Author: Edward Marco Baringer (Common Lisp)
;;         Matt Curtis <matt.r.curtis@gmail.com> (Emacs Lisp)
;; Maintainer: Matt Curtis <matt.r.curtis@gmail.com>
;; Version: 0.1
;; Keywords: csv
;; URL: https://github.com/mrc/el-csv

;; This file is not part of GNU Emacs.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions are
;; met:
;;
;;  - Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;;
;;  - Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;;
;;  - Neither the name of Edward Marco Baringer, nor BESE, nor the names
;;    of its contributors may be used to endorse or promote products
;;    derived from this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:
;;
;; Parse strings with CSV fields into s-expressions
;;
;; This file implements `parse-csv->list' and `parse-csv-string'.
;;
;; parse-csv-string is ported from Edward Marco Baringer's csv.lisp
;; http://common-lisp.net/project/bese/repos/arnesi_dev/src/csv.lisp
;; It was ported to Emacs Lisp by Matt Curtis.
;;
;; (parse-csv->list "a,b,\"c,d\"")
;;     => ("a" "b" "c,d")
;;
;; (parse-csv-string "a;b;'c;d'" ?\; ?\')
;;     => ("a" "b" "c;d")

;;; Code:

(require 'cl)

(defun parse-csv->list (row)
  "Parse a string ROW of comma-separated values into a list of strings.
Respects double-quoted strings (which may contain commas)."
  (parse-csv-string row ?\, ?\"))

(defun parse-csv-string (line separator quote-char)
  "Parse a separated and quoted string LINE into a list of strings.
Uses SEPARATOR as the column seperator and QUOTE-CHAR as the
string quoting character."
  (let ((items '())
        (offset 0)
        (current-word "")
        (state :read-word))
    (catch 'return
      (loop
       (when (= offset (length line))
         ;; all done
         (ecase state
           (:in-string
            (error "Unterminated string"))
           (:read-word
            (throw 'return
                   (nreverse (cons current-word items))))))
       (let ((current (aref line offset)))
         (cond
          ((char-equal separator current)
           (ecase state
             (:in-string
              (setq current-word (concat current-word (char-to-string current))))
             (:read-word
              (push current-word items)
              (setq current-word ""))))
          ((char-equal quote-char current)
           (ecase state
             (:in-string
              (let ((offset+1 (1+ offset)))
                (cond
                 ((and (/= offset+1 (length line))
                       (char-equal quote-char (aref line offset+1)))
                  (setq current-word (concat current-word (char-to-string quote-char)))
                  (incf offset))
                 (t (setq state :read-word)))))
             (:read-word
              (setq state :in-string))))
          (t
           (setq current-word (concat current-word (char-to-string current))))))
       (incf offset)))))

(provide 'parse-csv)

;; Local-Variables:
;; indent-tabs-mode: nil
;; End:

;;; parse-csv.el ends here
