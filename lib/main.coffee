{CompositeDisposable} = require 'atom'
path = require 'path'
_    = require 'underscore-plus'
CSON = require 'season'
fs   = require 'fs-plus'

userConfigTemplate = """
# '*' is wildcard scope, which is always searched finally.
#
# '*': [
#   ['yes'   , 'no']
#   ['up'    , 'down']
#   ['right' , 'left']
#   ['true'  , 'false']
#   ['high'  , 'low']
#   ['column', 'row']
#   ['and'   , 'or']
#   ['not'   , '']
#   ['on'    , 'off']
#   ['in'    , 'out']
#   ['one'   , 'two'   , 'three']
#   ['bar'   , 'bar']
# ],
# 'source.coffee': [
#   ['this', '@']
#   ['is'  , 'isnt']
#   ['if'  , 'unless']
# ]
"""

Config =
  configPath:
    order: 1
    type: 'string'
    default: path.join(atom.getConfigDirPath(), 'toggle.cson')
    description: 'filePath for words definitions'
  useDefaultWordGroup:
    order: 2
    type: 'boolean'
    default: true

module.exports =
  disposables: null
  userWordGroup: null
  defaultWordGroup: null
  config: Config

  activate: (state) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace',
      'toggle:here':        => @toggleHere()
      'toggle:there':       => @toggleThere()
      'toggle:open-config': => @openConfig()
      # 'toggle:readConfig': => @readConfig()

  deactivate: ->
    @disposables.dispose()

  serialize: ->

  detectCursorScope: (cursor) ->
    supportedScopeNames = _.pluck(atom.grammars.getGrammars(), 'scopeName')

    scopesArray = cursor.getScopeDescriptor().getScopesArray()
    scope = _.detect scopesArray.reverse(), (scope) -> scope in supportedScopeNames
    scope

  openConfig: ->
    filePath = @getConfigPath()
    fistOpen = not fs.existsSync(filePath)
    atom.workspace.open(@getConfigPath()).done (editor) =>
      if fistOpen
        editor.setText(userConfigTemplate)
        editor.save()
      @reloadUserWordGroupOnSave(editor)

  getConfigPath: ->
    fs.normalize(atom.config.get('toggle.configPath'))

  reloadUserWordGroupOnSave: (editor) ->
    @disposables = editor.onDidSave =>
      @userWordGroup = @readConfig()

  getUserWordGroup: ->
    @userWordGroup ?= @readConfig()

  getDefaultWordGroup: ->
    if atom.config.get('toggle.useDefaultWordGroup')
      @defaultWordGroup ?= require './word-group'
    else
      {}

  readConfig: ->
    filePath = @getConfigPath()
    return {} unless fs.existsSync(filePath)

    try
      config = CSON.readFileSync(filePath)
      return (config or {})
    catch error
      message = '[toggle] config file has error'
      options =
        detail: error.message
      atom.notifications.addError message, options

  getWord: (word, scope) ->
    defaultWordGroup = @getDefaultWordGroup()
    userWordGroup    = @getUserWordGroup()

    for scope in [scope, '*']
      for wordGroup in [userWordGroup, defaultWordGroup] when wordGroup[scope]
        words = _.detect(wordGroup[scope], (words) -> word in words)
        if words?
          index = words.indexOf(word)
          nextIndex = index + 1
          nextIndex = 0 if nextIndex is words.length
          return words[nextIndex]

    return null

  toggleWord: (cursor) ->
    range = cursor.getCurrentWordBufferRange()
    word = cursor.editor.getTextInBufferRange range
    scope = @detectCursorScope(cursor)
    newWord = @getWord word, scope
    if newWord?
      cursor.editor.setTextInBufferRange(range, newWord)
      return true
    else
      return false

  toggle: (cursor) ->
    position = cursor.getBufferPosition()
    if @toggleWord(cursor)
      cursor.setBufferPosition(position)
      return true
    else
      return false

  toggleHere: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    editor.transact =>
      @toggle(cursor) for cursor in editor.getCursors()

  toggleThere: ->
    return unless editor = atom.workspace.getActiveTextEditor()

    cursor   = editor.getLastCursor()
    position = cursor.getBufferPosition()
    until (cursor.getBufferRow() isnt position.row) or cursor.isAtEndOfLine()
      if @toggle(cursor)
        # return if
        break
      else
        cursor.moveToBeginningOfNextWord()
    cursor.setBufferPosition(position)
