# Toggle

Toggle keyword

![gif](https://raw.githubusercontent.com/t9md/t9md/98d528c75fdc11e98c79e52404d3a195d6dcb0ee/img/atom-toggle.gif)

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
'atom-text-editor.vim-mode.normal-mode':
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
atom-text-editor::shadow {
  .toggle-flash .region {
    background-color: @syntax-selection-flash-color;
  }
}
```

# Similar package for other text editors.

* [zef/vim-cycle](https://github.com/zef/vim-cycle)
* [AndrewRadev/switch.vim](https://github.com/AndrewRadev/switch.vim)
