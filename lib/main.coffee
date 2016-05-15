{CompositeDisposable} = require 'atom'
_    = require 'underscore-plus'
fs   = require 'fs-plus'
CSON = null

settings = require './settings'

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

module.exports =
  userWordGroup: null
  defaultWordGroup: null
  flasher: null
  config: settings.config

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-workspace',
      'toggle:here': => @toggle(where: 'here')
      'toggle:visit': => @toggle(restoreCursor: false)
      'toggle:there': => @toggle(restoreCursor: true)
      'toggle:open-config': => @openUserConfig()

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null

  subscribe: (arg) ->
    @subscriptions.add(arg)

  getScopeNameAtCursor: (cursor) ->
    scopeNames = _.pluck(atom.grammars.getGrammars(), 'scopeName')
    scopes = cursor.getScopeDescriptor().getScopesArray().reverse()
    _.detect(scopes, (scope) -> scope in scopeNames)

  getUserConfigPath: ->
    fs.normalize(settings.get('configPath'))

  openUserConfig: ->
    filePath = @getUserConfigPath()
    atom.workspace.open(filePath).then (editor) =>
      unless fs.existsSync(filePath)
        # First time!
        editor.setText(userConfigTemplate)
        editor.save()

      @subscribe editor.onDidSave =>
        @userWordGroup = @readConfig()

  getUserWordGroup: ->
    @userWordGroup ?= @readConfig()

  getDefaultWordGroup: ->
    if settings.get('useDefaultWordGroup')
      @defaultWordGroup ?= require './word-group'
    else
      {}

  readConfig: ->
    filePath = @getUserConfigPath()
    return {} unless fs.existsSync(filePath)

    try
      CSON ?= require 'season'
      return CSON.readFileSync(filePath) or {}
    catch error
      message = '[toggle] config file has error'
      options =
        detail: error.message
      atom.notifications.addError message, options
    {}

  getFlasher: ->
    @flasher ?= require './flasher'

  getWord: (word, scope) ->
    defaultWordGroup = @getDefaultWordGroup()
    userWordGroup = @getUserWordGroup()

    for _scope in [scope, '*']
      wordGroups = [userWordGroup[_scope]]
      unless (_scope in settings.get('defaultWordGroupExcludeScope'))
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
    range = cursor.getCurrentWordBufferRange()
    word = cursor.editor.getTextInBufferRange(range)
    scope = @getScopeNameAtCursor(cursor)
    newWord = @getWord(word, scope)
    if newWord? and (newWord isnt word) # [NOTE] Might be empty string.
      if settings.get('flashOnToggle')
        editor = cursor.editor
        marker = editor.markBufferRange range,
          invalidate: 'never'
          persistent: false
        range = marker.getBufferRange()
        @getFlasher().register(editor, marker)

      position = cursor.getBufferPosition()
      cursor.editor.setTextInBufferRange(range, newWord)
      cursor.setBufferPosition(position)
      return true
    else
      return false

  # Edit for each cursor, to restore cursor position, return true from callback.
  startEdit: (editor, fn) ->
    editor.transact ->
      for cursor in editor.getCursors()
        position = cursor.getBufferPosition()
        if fn(cursor)
          cursor.setBufferPosition(position)

    if settings.get('flashOnToggle')
      @getFlasher().flash
        class: 'toggle-flash'
        duration: settings.get('flashDurationMilliSeconds')

  # options
  # - where: ['here']
  # - restoreCursor: [true, false]
  toggle: (options={}) ->
    editor = atom.workspace.getActiveTextEditor()
    {where, restoreCursor} = options
    return unless editor
    @startEdit editor, (cursor) =>
      if where is 'here'
        @toggleWord(cursor)
        return false
      else
        found = null

        loop
          if found = @toggleWord(cursor)
            break

          beforePoint = cursor.getBufferPosition()
          cursor.moveToBeginningOfNextWord()
          afterPoint = cursor.getBufferPosition()

          if (beforePoint.row isnt afterPoint.row) or
              beforePoint.isEqual(afterPoint)
            break

        (not found) or restoreCursor
