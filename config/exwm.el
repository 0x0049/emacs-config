;;; exwm.el --- EXWM configuration. -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:

(when (display-graphic-p)
  (nconc package-selected-packages '(exwm exwm-edit)))

(setq exwm-edit-bind-default-keys nil)

(autoload 'exwm-edit "exwm-edit--compose")

(define-key global-map (kbd "C-c r") #'ec-exec)

(defcustom ec-monitor-xrandr-alist nil "Xrandr flags for each monitor."
  :type '(alist :key-type string :value-type string)
  :group 'exwm)

(defun ec-exec (&rest args)
  "Execute ARGS asynchronously without a buffer.
ARGS are simply concatenated with spaces.
If no ARGS are provided, prompt for the command."
  (interactive (list (read-shell-command "$ ")))
  (let ((command (mapconcat 'identity args " " )))
    (set-process-sentinel
     (start-process-shell-command command nil command)
     (lambda (_ event)
       (message "%s: %s" (car args) (string-trim event))))))

(advice-add 'exwm-manage--manage-window :around #'ec-localize)

;; Used to determine if the screen script needs to run.
(defvar ec--connected-monitors nil "Currently connected monitors.")

(setq exwm-input-global-keys
      `((,(kbd "s-q") . exwm-input-send-next-key)
        (,(kbd "s-c") . exwm-input-grab-keyboard)
        (,(kbd "s-e") . exwm-edit--compose)

        (,(kbd "<s-tab>")         . ec-exwm-workspace-next)
        (,(kbd "<s-iso-lefttab>") . ec-exwm-workspace-prev)

        (,(kbd "s-j") . evil-window-down)
        (,(kbd "s-k") . evil-window-up)
        (,(kbd "s-l") . evil-window-right)
        (,(kbd "s-h") . evil-window-left)
        (,(kbd "s-x") . ec-exwm-update-screens)
        (,(kbd "<s-left>") . (lambda () (interactive) (ec-exwm-rotate-screen 'left)))
        (,(kbd "<s-up>") . (lambda () (interactive) (ec-exwm-rotate-screen 'inverted)))
        (,(kbd "<s-right>") . (lambda () (interactive) (ec-exwm-rotate-screen 'right)))
        (,(kbd "<s-down>") . (lambda () (interactive) (ec-exwm-rotate-screen 'normal)))

        (,(kbd "s-J") . evil-window-decrease-height)
        (,(kbd "s-K") . evil-window-increase-height)
        (,(kbd "s-L") . evil-window-increase-width)
        (,(kbd "s-H") . evil-window-decrease-width)

        (,(kbd "<XF86MonBrightnessUp>")   . (lambda () (interactive) (ec-exec "light -A 5")))
        (,(kbd "<XF86MonBrightnessDown>") . (lambda () (interactive) (ec-exec "light -U 5")))
        (,(kbd "<XF86AudioLowerVolume>")  . (lambda () (interactive) (ec-exec "pamixer --decrease 1")))
        (,(kbd "<XF86AudioRaiseVolume>")  . (lambda () (interactive) (ec-exec "pamixer --increase 1")))
        (,(kbd "<XF86AudioMute>")         . (lambda () (interactive) (ec-exec "pamixer --toggle-mute")))
        (,(kbd "<XF86AudioMicMute>")      . (lambda () (interactive) (ec-exec "pamixer --default-source --toggle-mute")))
        (,(kbd "<XF86AudioPause>")        . (lambda () (interactive) (ec-exec "playerctl play-pause")))
        (,(kbd "<XF86AudioPlay>")         . (lambda () (interactive) (ec-exec "playerctl play-pause")))
        (,(kbd "<XF86AudioPrev>")         . (lambda () (interactive) (ec-exec "playerctl previous")))
        (,(kbd "<XF86AudioNext>")         . (lambda () (interactive) (ec-exec "playerctl next")))))

(setq exwm-input-simulation-keys
      `((,(kbd "j")        . [down])
        (,(kbd "k")        . [up])
        (,(kbd "l")        . [right])
        (,(kbd "h")        . [left])
        (,(kbd "C-u")      . [prior])
        (,(kbd "C-d")      . [next])
        (,(kbd "C-H")      . [C-prior])
        (,(kbd "C-L")      . [C-next])
        (,(kbd "H")        . [M-left])
        (,(kbd "L")        . [M-right])
        (,(kbd "<tab>")    . [tab])
        (,(kbd "<return>") . [return])))

(setq exwm-input-line-mode-passthrough t
      exwm-manage-configurations '((t char-mode t)))

(defun ec--exwm-update-title ()
  "Rename the buffer to `exwm-title'."
  (exwm-workspace-rename-buffer (concat "*" exwm-title "*")))

(add-hook 'exwm-update-title-hook #'ec--exwm-update-title)

(defun ec--exwm-workspace-switch (n)
  "Switch to the workspace N away from the current."
  (let* ((workspaceCount (exwm-workspace--count))
         (targetIndex (+ n exwm-workspace-current-index))
         (over? (>= targetIndex workspaceCount))
         (under? (< targetIndex 0)))
    (cond (over? (exwm-workspace-switch 0))
          (under? (exwm-workspace-switch (- workspaceCount 1)))
          (t (exwm-workspace-switch targetIndex)))))

(defun ec-exwm-workspace-prev ()
  "Move to the previous workspace."
  (interactive)
  (ec--exwm-workspace-switch -1))

(defun ec-exwm-workspace-next ()
  "Move to the next workspace."
  (interactive)
  (ec--exwm-workspace-switch 1))

(defun ec-exwm-update-screens ()
  "Update screens when they change."
  (interactive)
  (let* ((default-directory "~")
         (xrandr (shell-command-to-string "xrandr"))
         (monitors
          (mapcar (lambda (s) (car (split-string s " ")))
                  (seq-filter (lambda (s) (string-match " connected" s))
                              (split-string xrandr "\n")))))
    (unless (and (not (called-interactively-p)) (equal ec--connected-monitors monitors))
      (let ((command (concat
                      "xrandr "
                      (mapconcat
                       (lambda (m) (format "--output %s %s" m (cdr (assoc m ec-monitor-xrandr-alist))))
                       monitors
                       " ")
                      " "
                      (mapconcat
                       (lambda (m) (format "--output %s --off" m))
                       (seq-difference ec--connected-monitors monitors)
                       " "))))
        (when (or (bound-and-true-p ec-debug-p) (called-interactively-p))
          (message ">>> %s" command))
        (unless monitors
          (message ">>> %s" xrandr)
          (error "Refusing to turn off all monitors"))
        (setq ec--connected-monitors monitors)
        (ec-exec command)))))

(defcustom ec-touchscreen-plist nil "Xrandr and xinput ids of the touchscreen."
  :type '(plist :key-type (choice (const :xrandr) (const :xinput))
                :value-type (choice string (repeat string)))
  :group 'exwm)

(defvar ec--monitor-rotation-transformations '((normal . "1 0 0 0 1 0 0 0 1")
                                               (inverted . "-1 0 1 0 -1 1 0 0 1")
                                               (left . "0 -1 1 1 0 0 0 0 1")
                                               (right . "0 1 0 -1 0 1 0 0 1"))
  "Transformation matrices for monitor rotations.")

(defun ec-exwm-rotate-screen (new-rotation)
  "Rotate a connected monitor to NEW-ROTATION.

If the monitor is a touchscreen also adjust the touch input."
  (interactive)
  (let* ((monitor (if (= 1 (length ec--connected-monitors))
                      (car ec--connected-monitors)
                    (completing-read "Monitor: " ec--connected-monitors nil t)))
         (default-directory "~")
         (xrandr (shell-command-to-string "xrandr"))
         (command (format "xrandr --output %s --rotate %s"
                          monitor
                          new-rotation))
         (rotation (alist-get new-rotation ec--monitor-rotation-transformations)))
    (message ">>> %s" command)
    (ec-exec command)
    (when (string= monitor (plist-get ec-touchscreen-plist :xrandr))
      (dolist (device (plist-get ec-touchscreen-plist :xinput))
        (let ((command (format
                        "xinput set-prop '%s' 'Coordinate Transformation Matrix' %s"
                        device
                        rotation)))
          (message ">>> %s" command)
          (ec-exec command))))))

(defun ec--exwm-update-screens-soon ()
  "Update screens soon."
  (timer-idle-debounce #'ec-exwm-update-screens 5))

(add-hook 'exwm-randr-screen-change-hook #'ec--exwm-update-screens-soon)

(with-eval-after-load 'exwm
  (define-key exwm-mode-map (kbd "C-w") #'evil-window-map)
  (define-key exwm-mode-map (kbd "i") #'exwm-input-release-keyboard)
  (define-key exwm-mode-map (kbd ":") #'evil-ex)

  (ec-exwm-update-screens)

  (require 'exwm-randr)
  (exwm-randr-enable))

(with-eval-after-load 'evil
  (evil-set-initial-state 'exwm-mode 'emacs))

;;; exwm.el ends here
