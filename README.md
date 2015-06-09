# Toggle

Toggle word at cursor

# Development state

Alpha

Currently implemented only very simple toggle feature.

# Keymap

**No keymap by default**.

e.g.

* normal user

```coffeescript
'atom-text-editor:not([mini])':
  'ctrl-t': 'try:paste'
```

* [vim-mode](https://atom.io/packages/vim-mode)?.

```coffeescript
'atom-text-editor.vim-mode.command-mode':
  '-': 'toggle:toggle'
```


# Similar package for other text editors.

* [zef/vim-cycle](https://github.com/zef/vim-cycle)
* [AndrewRadev/switch.vim](https://github.com/AndrewRadev/switch.vim)

# TODO
* [ ] Support language specific keyword handling
* [ ] Customize toggle function by user's function.
