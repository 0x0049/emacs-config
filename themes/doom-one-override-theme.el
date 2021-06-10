;;; doom-one-override-theme.el --- Doom One theme overrides. -*- lexical-binding: t -*-

;;; Commentary:

;;; Code:

(ec-def-theme
 doom-one-override "Doom One theme overrides"

 (region              :background (doom-blend (doom-color 'blue) (doom-color 'bg) 0.05))
 (highlight           :background (doom-blend (doom-color 'red) (doom-color 'bg) 0.2))
 (secondary-selection :underline  (doom-color 'orange))

 (evil-normal-state   :foreground (doom-color 'yellow))
 (evil-insert-state   :foreground (doom-color 'green))
 (evil-emacs-state    :foreground (doom-color 'blue))
 (evil-replace-state  :foreground (doom-color 'red))
 (evil-visual-state   :foreground (doom-color 'base7))
 (evil-motion-state   :foreground (doom-color 'magenta))
 (evil-operator-state :foreground (doom-color 'violet))

 (fill-column-indicator :foreground (doom-color 'bg-alt)))

;;; doom-one-override-theme.el ends here
