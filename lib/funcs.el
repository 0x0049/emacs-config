;;; funcs.el --- Utility functions. -*- lexical-binding: t -*-

;;; Commentary:

;;

;;; Code:

(defun ec-diff (a b)
  "Focus the frame and diff A with B."
  (select-frame-set-input-focus (selected-frame))
  (ediff-files a b))

;; You can use the T flag to compute time durations but I can't get that to work
;; while still being able to do a regex match on the date, so this is the
;; solution. I keep a running total of overtime or time I need to make up using
;; the following:
;;
;; #+TBLFM: $3='(0x0049/to-string (- (+ (cond ((= @# 2) $start) (t
;; (0x0049/to-seconds "@-1"))) (cond ((string-match-p "Sat\\|Sun" "$1") 0) (t
;; $per))) (0x0049/to-seconds "$2")));L
;;
;; Where $per = seconds to work per day and $start = current overtime or time to
;; make up before the table started (also in seconds). The table has the
;; following columns: "Date"", "Time" (HH:MM format), and "Remaining".
(defun ec-to-seconds (s)
  "Convert string S in %H:%M:%S, %H:%M, and %S formats to seconds."
  (cond ((stringp s)
         (let ((sign (if (string-match "^-" s) -1 1)))
           (cond ((string-match "\\([0-9]+\\):\\([0-9]+\\):\\([0-9]+\\)" s)
                  (let ((hour (string-to-number (match-string 1 s)))
                        (min (string-to-number (match-string 2 s)))
                        (sec (string-to-number (match-string 3 s))))
                    (* (+ (* hour 3600) (* min 60) sec) sign)))
                 ((string-match "\\([0-9]+\\):\\([0-9]+\\)" s)
                  (let ((hour (string-to-number (match-string 1 s)))
                        (min (string-to-number (match-string 2 s))))
                    (* (+ (* hour 3600) (* min 60)) sign)))
                 (t (string-to-number s)))))
        (t s)))

;; format-seconds doesn't seem to handle negative seconds correctly.
(defun ec-format-seconds (seconds)
  "Convert number SECONDS to hours:minutes."
  (cond ((>= seconds 0) (format-seconds "%h:%.2m" seconds))
        (t (concat "-" (format-seconds "%h:%.2m" (* seconds -1))))))

(defun ec-center-truncate (item len)
  "Replace the center of ITEM with … to make it of length LEN (including …).

When the length is odd the right side will be one longer than the left."
  (let ((item (if (stringp item) item (format "%s" item))))
    (if (> (length item) len)
        (let* ((len (- len 1))
               (mid (/ len 2)))
          (concat (substring item 0 mid)
                  (apply #'propertize "…" (text-properties-at (- mid 1) item))
                  (substring item (- mid len) nil)))
      item)))

(defun ec-run-and-bury (fn &rest args)
  "Run the FN with ARGS then bury the current buffer."
  (let ((buf (buffer-name)))
    (apply fn args)
    (bury-buffer buf)))

;;; funcs.el ends here
