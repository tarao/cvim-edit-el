cvim-edit.el --- cVim Edit Server on Emacs
==========================================

## Install by el-get

1. Setup [el-get](https://github.com/dimitri/el-get)
2. Put the following code in your Emacs init file (`~/.emacs` or `~/.emacs.d/init.el`)

```lisp
(el-get-bundle tarao/cvim-edit-el
  :depends elnode)
```

## Usage

- `.cvimrc`

  ```
  imap <C-x> editWithVim
  ```

- `~/.emacs.d/init.el`

  ```lisp
  (require 'cvim-edit)
  (cvim-edit:server-start)
  ```

## Customization

- `cvim-edit:server-port` (default: `8001`)

  Port number of cVim edit server.  Specify the same value as `vimport` in your `.cvimrc`.

- `cvim-edit:buffer-name` (default: `*cvim*`)

  Buffer name of cVim edit buffer.

- `cvim-edit:major-mode` (default: `'text-mode`)

  Major mode of cVim edit buffer.
