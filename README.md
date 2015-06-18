# Toggle

Toggle word
 - at cursor
 - on current line even without changing cursor position.

![gif](https://raw.githubusercontent.com/t9md/t9md/1c92b38b8e1e8c2fd592f3befcd673f896246271/img/atom-toggle.gif)

# Features

* Toggle word under cursor(`toggle:here`) to next word in wordGroup.
* Toggle word on current line with(`toggle:visit`) or without(`toggle:there`) changing cursor position.
* User configurable wordGroup.
* Use cursor position's scope(usefull in like `coffeescript` in `gfm`).
* Scope specific and default(`*`) wordGroup.
* Open user configration(`toggle:open-config`), auto reload on save.
* Work with multiple cursor.
* You can disable default wordGroup completely.
* You can disable default wordGroup for specific scope.

# Commands

* `toggle:here`: toggle word under cursor.
* `toggle:there`: toggle word on current line without changing cursor position.
* `toggle:visit`: toggle word on current line with visiting toggled word.
* `toggle:open-config`: open user's wordGroup configuration file.

# Keymap

**No keymap by default**.

e.g.

* normal user

```coffeescript
'atom-text-editor:not([mini])':
  'ctrl--': 'toggle:there'
```

* [vim-mode](https://atom.io/packages/vim-mode)?.

```coffeescript
'atom-text-editor.vim-mode.command-mode':
  '-': 'toggle:there'
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
* [x] Toggle without changing cursor position.
* [ ] Highlight toggled word?
* [ ] Improve default words group.
