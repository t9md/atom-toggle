{CompositeDisposable} = require 'atom'
path = require 'path'
_    = require 'underscore-plus'
CSON = require 'season'
fs   = require 'fs-plus'

userConfigTemplate = """
# '*' is wildcard which is always searched finally.
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
  defaultWordGroupExcludeScope:
    order: 3
    type: 'array'
    default: []
    items:
      type: 'string'
    description: 'Default wordGrop is not used for scope in this list'

module.exports =
  disposables: null
  userWordGroup: null
  defaultWordGroup: null
  config: Config

  activate: (state) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace',
      'toggle:here':        => @toggle(where: 'here')
      'toggle:visit':       => @toggle(restoreCursor: false)
      'toggle:there':       => @toggle(restoreCursor: true)
      'toggle:open-config': => @openConfig()

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
    atom.workspace.open(filePath).done (editor) =>
      unless fs.existsSync(filePath)
        # First time!
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
    # @userWordGroup.slice()

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

  debug:  ->
    console.log @getDefaultWordGroup()
    console.log @getUserWordGroup()

  getWord: (word, scope) ->
    defaultWordGroup = @getDefaultWordGroup()
    userWordGroup    = @getUserWordGroup()

    for _scope in [scope, '*']
      wordGroups = [userWordGroup[_scope]]
      unless (_scope in atom.config.get('toggle.defaultWordGroupExcludeScope'))
        wordGroups.push defaultWordGroup[_scope]
      wordGroups = _.filter wordGroups, (e) -> _.isArray(e)

      for wordGroup in wordGroups
        words = _.detect(wordGroup, (words) -> word in words)
        if words?
          index = words.indexOf(word)
          nextIndex = index + 1
          nextIndex = 0 if nextIndex is words.length
          return words[nextIndex]

    return null

  toggleWord: (cursor) ->
    range   = cursor.getCurrentWordBufferRange()
    word    = cursor.editor.getTextInBufferRange range
    scope   = @detectCursorScope(cursor)
    newWord = @getWord word, scope
    if newWord? # [NOTE] Might be empty string.
      position = cursor.getBufferPosition()
      cursor.editor.setTextInBufferRange range, newWord
      cursor.setBufferPosition position
      return true
    else
      return false

  # Edit for each cursor, to restore cursor position, return true from callback.
  startEdit: (callback) ->
    return unless editor = atom.workspace.getActiveTextEditor()
    editor.transact =>
      for cursor in editor.getCursors()
        position = cursor.getBufferPosition()
        if callback(cursor)
          cursor.setBufferPosition(position)

  toggle: (options={}) ->
    @startEdit (cursor) =>
      if options.where is 'here'
        @toggleWord cursor
        return false
      else
        found = null
        orignalRow = cursor.getBufferRow()
        until (cursor.getBufferRow() isnt orignalRow) or cursor.isAtEndOfLine()
          break if found = @toggleWord(cursor)
          cursor.moveToBeginningOfNextWord()

        (not found) or options.restoreCursor
