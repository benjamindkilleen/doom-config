;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Benjamin D. Killeen"
      user-mail-address "benjamindkilleen@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function.
(setq doom-theme 'doom-gruvbox)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type nil)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(add-to-list 'default-frame-alist '(inhibit-double-buffering . t))
(setq projectile-project-search-path
 '("~/projects/" "~/writing/" "~/jhu/" "~/projects/tutoring/" "~/papers"))
(remove-hook 'doom-first-buffer-hook #'smartparens-global-mode)
(setq-default fill-column 100)          ; TODO: make "default line width" based on editorconfig
;; (setq zen-mode-margin-width 100)

;; Mappings
(map!
 :leader
 :desc "Auto-fill mode" "t a" 'auto-fill-mode)

;; Re-map "j-k" to escape when in INSERT mode.
(use-package! key-chord)
(key-chord-mode 1)
(key-chord-define evil-insert-state-map  "jk" 'evil-normal-state)

;; adjust indentation
(defun unindent-dwim (&optional count-arg)
  "Keeps relative spacing in the region.  Unindents to the next multiple of the current tab-width"
  (interactive)
  (let ((deactivate-mark nil)
        (beg (or (and mark-active (region-beginning)) (line-beginning-position)))
        (end (or (and mark-active (region-end)) (line-end-position)))
        (min-indentation)
        (count (or count-arg 1)))
    (save-excursion
      (goto-char beg)
      (while (< (point) end)
        (add-to-list 'min-indentation (current-indentation))
        (forward-line)))
    (if (< 0 count)
        (if (not (< 0 (apply 'min min-indentation)))
            (error "Can't indent any more.  Try `indent-rigidly` with a negative arg.")))
    (if (> 0 count)
        (indent-rigidly beg end (* (- 0 tab-width) count))
      (let (
            (indent-amount
             (apply 'min (mapcar (lambda (x) (- 0 (mod x tab-width))) min-indentation))))
        (indent-rigidly beg end (or
                                 (and (< indent-amount 0) indent-amount)
                                 (* (or count 1) (- 0 tab-width))))))))
(global-set-key (kbd "s-[") 'unindent-dwim)
(global-set-key (kbd "s-]") (lambda () (interactive) (unindent-dwim -1)))

;; LaTeX config
;; TODO: not working for some reason.
;; (add-hook! tex-mode 'hl-todo-mode)
(setq! flycheck-checker-error-threshold 1001)

;;
;; TeXcount setup for TeXcount version 2.3 and later
;;
(defun texcount ()
  (interactive)
  (let*
      ( (this-file (buffer-file-name))
        (enc-str (symbol-name buffer-file-coding-system))
        (enc-opt
         (cond
          ((string-match "utf-8" enc-str) "-utf8")
          ((string-match "latin" enc-str) "-latin1")
          ("-encoding=guess")
          ) )
        (word-count
         (with-output-to-string
           (with-current-buffer standard-output
             (call-process "texcount" nil t nil "-0" "-merge" enc-opt this-file)
             ) ) ) )
    (message word-count)
    ) )
(map!
 :after tex-mode
 :leader
 :desc "Word count" "f w" 'texcount )

;; Python
;; (add-hook! 'python-mode-hook (modify-syntax-entry ?_ "w"))
;; poetry
(use-package! poetry
  :ensure t
  :hook
  ;; activate poetry-tracking-mode when python-mode is active
  (python-mode . poetry-tracking-mode)
  )

;; ....

;; lsp-mode configs
(use-package lsp-mode
  :ensure t
  :init
  (setq lsp-keymap-prefix "C-c l")
  :custom
  (lsp-auto-guess-root +1)
  :config
  (lsp-enable-imenu)
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         (python-mode . lsp-deferred)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration)
	 (lsp-after-open . 'lsp-enable-imenu)
	 )
  :commands (lsp lsp-deferred))

;; lsp Python
(use-package lsp-python-ms
  :after poetry
  :ensure t
  :init
  (setq lsp-python-ms-auto-install-server t)
  :config
  (put 'lsp-python-ms-python-executable 'safe-local-variable 'stringp)
  ;; attempt to activate Poetry env first
  (when (stringp (poetry-find-project-root))
    (poetry-venv-workon)
    )
  :hook
  (
   (python-mode . (lambda ()
                    (require 'lsp-python-ms)
                    (lsp-deferred)
                    ))
   ;; if .dir-locals exists, read it first, then activate mspyls
   (hack-local-variables . (lambda ()
                             (when (derived-mode-p 'python-mode)
                               (require 'lsp-python-ms)
                               (lsp-deferred))
                             ))
   )
  )

;; Pyenv in projectile
;; (require 'pyenv-mode)

;; (defun projectile-pyenv-mode-set ()
;;   "Set pyenv version matching project name."
;;   (let ((project (projectile-project-name)))
;;     (if (member project (pyenv-mode-versions))
;;         (pyenv-mode-set project)
;;       (pyenv-mode-unset))))

;; (add-hook 'projectile-after-switch-project-hook 'projectile-pyenv-mode-set)

;; Haskell
(custom-set-variables
 '(haskell-stylish-on-save t))

;; Treemacs superfluous files
(after! treemacs
  (defvar treemacs-file-ignore-extensions '()
    "File extension which `treemacs-ignore-filter' will ensure are ignored")
  (defvar treemacs-file-ignore-globs '()
    "Globs which will are transformed to `treemacs-file-ignore-regexps' which `treemacs-ignore-filter' will ensure are ignored")
  (defvar treemacs-file-ignore-regexps '()
    "RegExps to be tested to ignore files, generated from `treeemacs-file-ignore-globs'")
  (defun treemacs-file-ignore-generate-regexps ()
    "Generate `treemacs-file-ignore-regexps' from `treemacs-file-ignore-globs'"
    (setq treemacs-file-ignore-regexps (mapcar 'dired-glob-regexp treemacs-file-ignore-globs)))
  (if (equal treemacs-file-ignore-globs '()) nil (treemacs-file-ignore-generate-regexps))
  (defun treemacs-ignore-filter (file full-path)
    "Ignore files specified by `treemacs-file-ignore-extensions', and `treemacs-file-ignore-regexps'"
    (or (member (file-name-extension file) treemacs-file-ignore-extensions)
        (let ((ignore-file nil))
          (dolist (regexp treemacs-file-ignore-regexps ignore-file)
            (setq ignore-file (or ignore-file (if (string-match-p regexp full-path) t nil)))))))
  (add-to-list 'treemacs-ignored-file-predicates #'treemacs-ignore-filter))

;; And list the files
(setq treemacs-file-ignore-extensions
      '(;; LaTeX
        "aux"
        "ptc"
        "fdb_latexmk"
        "fls"
        "synctex.gz"
        "toc"
        "out"
        "log"
        ;; LaTeX - glossary
        "glg"
        "glo"
        "gls"
        "glsdefs"
        "ist"
        "acn"
        "acr"
        "alg"
        ;; LaTeX - pgfplots
        "mw"
        ;; LaTeX - pdfx
        "pdfa.xmpi"
        ))
(setq treemacs-file-ignore-globs
      '(;; LaTeX
        "*/_minted-*"
        ;; AucTeX
        "*/.auctex-auto"
        "*/_region_.log"
        "*/_region_.tex"))
