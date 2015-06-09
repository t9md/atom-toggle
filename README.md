# Toggle

Toggle word at cursor

![gif](https://raw.githubusercontent.com/t9md/t9md/846644d6d84621ec8d2b2405d1b0059c9a357714/img/atom-toggle.gif)

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
* [ ] Customizable toggle behavior by user function.
