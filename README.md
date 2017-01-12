# Toggle [![Build Status](https://travis-ci.org/t9md/atom-toggle.svg?branch=master)](https://travis-ci.org/t9md/atom-toggle)

Toggle keyword

![gif](https://raw.githubusercontent.com/t9md/t9md/1b7e5e194459078e30a85443b283561a4ff8edbe/img/atom-toggle.gif)

# Commands

* `toggle:here`: Toggle word under cursor.
* `toggle:there`: Toggle word on current line without moving cursor.
* `toggle:visit`: Toggle word on current line and move to toggled word.
* `toggle:open-config`: Open user's wordGroup configuration file.

# Keymap

**No keymap by default**.

e.g.

* normal user

```coffeescript
'atom-text-editor:not([mini])':
  'ctrl--': 'toggle:there'
```

* [vim-mode-plus](https://atom.io/packages/vim-mode-plus) user

```coffeescript
'atom-text-editor.vim-mode-plus.normal-mode':
  '-': 'toggle:there'
```

# Limitation

When this package search candidate word to be toggled from current line, it scan word with regular expression `/\b\w+\b/`.  
So you can only toggle word matches `\w+` or `[A-Za-z0-9_]+`.  
This mean you cannot set special character as toggle words e.g. `<`, `<=`.

# Customization

### Add custom words

From command Palette, execute `Toggle: Open Config`.

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
  ['is'  , 'isnt']
  ['if'  , 'unless']
]
```

### Flash color customization

```less
@keyframes toggle-flash {
  from { background-color: @syntax-selection-flash-color; }
  to { background-color: transparent; }
}
```

# Similar package for other text editors.

* [zef/vim-cycle](https://github.com/zef/vim-cycle)
* [AndrewRadev/switch.vim](https://github.com/AndrewRadev/switch.vim)
