# Toggle

Toggle word at cursor

![gif](https://raw.githubusercontent.com/t9md/t9md/846644d6d84621ec8d2b2405d1b0059c9a357714/img/atom-toggle.gif)

# Features

* Toggle word under cursor to next word in wordGroup.
* User configurable wordGroup.
* Scope specific and default(`*`) wordGroup.
* User cursor position's scope(usefull in like `coffeescript` in `gfm`).
* Auto reload user configuration on save.
* Work with multiple cursor.

# Commands

* `toggle:here`: toggle word under cursor.
* `toggle:there`: toggle word under cursor.
* `toggle:open-config`: open user's word group configuration file.

# Keymap

**No keymap by default**.

e.g.

* normal user

```coffeescript
'atom-text-editor:not([mini])':
  'ctrl--': 'toggle:here'
```

* [vim-mode](https://atom.io/packages/vim-mode)?.

```coffeescript
'atom-text-editor.vim-mode.command-mode':
  '-': 'toggle:here'
```

# Configuration

```coffeescript
# '*' is wildcard scope, which is always searched as last resort.
'*': [
  ['yes'   , 'no']
  ['up'    , 'down']
  ['right' , 'left']
  ['true'  , 'false']
  ['high'  , 'low']
  ['column', 'row']
  ['and'   , 'or']
  ['not'   , '']
  ['on'    , 'off']
  ['in'    , 'out']
  ['one'   , 'two'   , 'three']
  ['bar'   , 'bar']
],
'source.coffee': [
  ['this', '@']
  ['is'  , 'isnt']
  ['if'  , 'unless']
]
```

# Similar package for other text editors.

* [zef/vim-cycle](https://github.com/zef/vim-cycle)
* [AndrewRadev/switch.vim](https://github.com/AndrewRadev/switch.vim)

# TODO
* [x] Support language specific keyword handling
* [x] Disable default words group by configuration.
* [ ] `toggle:there` to go and toggle.
* [ ] Improve default words group.
