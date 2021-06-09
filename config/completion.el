;;; completion.el --- Provide completion. -*- lexical-binding: t -*-

;;; Commentary:

;; Completions for code, files, keys, etc and anything to do with prompts.

;;; Code:

(setq history-delete-duplicates t)

;; Apropos.
(setq apropos-do-all t)

;; Which-key.
(setq which-key-idle-delay 0.2)

(defun ec--split-name (name)
  "Split NAME into its prefix and suffix."
  (and name
       (save-match-data
         (when (string-match
                "^\\(\\([^/]+\\)\\(/\\)+\\|\\([^-]+\\)\\(-\\)+\\)\\(.+\\)$"
                name)
           (list (or (match-string 2 name) (match-string 4 name))
                 (or (match-string 3 name) (match-string 5 name))
                 (match-string 6 name))))))

(defun ec--replace-then-run (fn key-binding &optional prefix)
  "Call FN with stripped KEY-BINDING and PREFIX."
  (let* ((name (cdr key-binding))
         (split (ec--split-name name)))
    (if (and split
             (or (equal (nth 0 split) "ec")
                 (featurep (intern (nth 0 split)))))
        (apply fn `(,(car key-binding) . ,(nth 2 split)) prefix nil)
      (apply fn key-binding prefix nil))))

(advice-add 'which-key--maybe-replace :around 'ec--replace-then-run)

(add-hook 'emacs-startup-hook #'which-key-mode)

(with-eval-after-load 'which-key
  ;; Instead of -0, display 0..9
  (push '((nil . "select-window-0-or-10") . ("0..9" . "window 0..9"))
        which-key-replacement-alist)
  ;; Don't show the 1-9 bindings.
  (push '((nil . "select-window-[1-9]") . t) which-key-replacement-alist)

  (which-key-add-key-based-replacements
    "C-c !" "flycheck"
    "C-c o" "org"
    "C-c oh" "heading"
    "C-c f" "files"
    "C-c &" "snippet"
    "C-c b" "buffer"
    "C-c p" "projectile"
    "C-c s" "scratch"
    "C-c w" "window"
    "C-c g" "git"

    "C-c l" "lsp"
    "C-c l =" "format"
    "C-c l F" "workspace"
    "C-c l G" "peek"
    "C-c l T" "toggle"
    "C-c l a" "action"
    "C-c l g" "goto"
    "C-c l h" "help"
    "C-c l r" "rename"
    "C-c l s" "server"))

(add-hook 'text-mode-hook #'yas-minor-mode)
(add-hook 'prog-mode-hook #'yas-minor-mode)

;; Snippets.
(with-eval-after-load 'yasnippet
  (define-key yas-minor-mode-map (kbd "TAB") #'hippie-expand)
  (push #'yas-hippie-try-expand hippie-expand-try-functions-list))

;; Company.
(setq-default company-frontends '(company-preview-frontend
                                  company-echo-frontend)
              company-minimum-prefix-length 1
              company-idle-delay 0.2)

(defun ec--company-add-snippet-backend(backend)
  (if (and (listp backend) (member 'company-yasnippet backend))
      backend
    (append (if (consp backend) backend (list backend))
            '(:with company-yasnippet))))

(with-eval-after-load 'company
  (define-key company-active-map [return] nil)
  (define-key company-active-map (kbd "RET") nil)

  (setq company-backends
        (mapcar #'ec--company-add-snippet-backend company-backends)))

(add-hook 'text-mode-hook #'company-mode)
(add-hook 'prog-mode-hook #'company-mode)

;; Man pages.
(setq Man-notify-method 'aggressive)

;; Ispell.
(setq ispell-personal-dictionary
      (expand-file-name "aspell/dictionary" ec-cache-dir)
      ;; Make curly quotes work with spellcheck.
      ispell-local-dictionary-alist
      '((nil "[[:alpha:]]" "[^[:alpha:]]" "['’]" nil ("-B") nil utf-8))
      ispell-extra-args
      `("--repl" ,(expand-file-name "aspell/replacements" ec-cache-dir)))

(add-hook 'text-mode-hook #'ispell-minor-mode)
(add-hook 'prog-mode-hook #'ispell-minor-mode)

;; `ding' aborts macros so disable it to make them always complete (ispell for
;; example will trigger this if it thinks a word is misspelled).
(advice-add #'ding :override #'ignore)

;; Savehist.
(setq savehist-file (expand-file-name "savehist" user-emacs-directory)
      history-length 10000
      savehist-additional-variables '(mark-ring
                                      global-mark-ring
                                      search-ring
                                      regexp-search-ring
                                      extended-command-history)
      savehist-autosave-interval 60)

(add-hook 'emacs-startup-hook #'savehist-mode)

;; Fido.
(setq icomplete-compute-delay 0.1
      icomplete-separator " "
      icomplete-prospects-height 1)

(add-hook 'emacs-startup-hook #'fido-mode)

;; Flimenu.
(define-key global-map (kbd "C-c bI") #'imenu)

(add-hook 'emacs-startup-hook #'flimenu-global-mode)

;; Ask y/n instead of yes/no.
(defalias 'yes-or-no-p 'y-or-n-p)

;;; completion.el ends here