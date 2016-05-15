{CompositeDisposable} = require 'atom'
fs = require 'fs-plus'
CSON = null

settings = require './settings'

userConfigTemplate = """
# Each word must match reglar expression '\w+'.
# So follwoing settings is invalid.
# e.g-1) both '<' and '>' not match '\w+'
#  ['<', '>']
#
# e.g-2) OK(this -> @), NG(@ -> this) `@` not match '\w+'
#  ['this', '@']
#
# '*' is wildcard which is always searched finally.
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
#   ['is'  , 'isnt']
#   ['if'  , 'unless']
# ]
"""

module.exports =
  config: settings.config

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    settings.notifyAndDelete('flashOnToggle')
    @subscribe atom.commands.add 'atom-workspace',
      'toggle:here': => @toggle('here')
      'toggle:visit': => @toggle('visit')
      'toggle:there': => @toggle('there')
      'toggle:open-config': => @openUserConfig()

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null

  subscribe: (arg) ->
    @subscriptions.add(arg)

  getScopeNameAtCursor: (cursor) ->
    scopeNames = (g.scopeName for g in atom.grammars.getGrammars())
    scopes = cursor.getScopeDescriptor().getScopesArray().reverse()
    for scope in scopes when scope in scopeNames
      return scope

  getUserConfigPath: ->
    fs.normalize(settings.get('configPath'))

  openUserConfig: ->
    filePath = @getUserConfigPath()
    disposable = null
    atom.workspace.open(filePath).then (editor) =>
      unless fs.existsSync(filePath)
        # First time!
        editor.setText(userConfigTemplate)
        editor.save()

      disposable = editor.onDidSave =>
        @userWordGroup = @readUserConfig()
      editor.onDidDestroy ->
        disposable.dispose()
        disposable = null

  getUserConfig: (scopeName) ->
    @userWordGroup ?= @readUserConfig()
    @userWordGroup[scopeName] ? []

  getDefaultConfig: (scopeName) ->
    if settings.get('useDefaultWordGroup')
      @defaultWordGroup ?= require './word-group'
      @defaultWordGroup[scopeName] ? []
    else
      []

  readUserConfig: ->
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

  getWord: (text, scopeName) ->
    findWord = (text, setOfWords) ->
      for words in setOfWords when (index = words.indexOf(text)) >= 0
        index = (index + 1) % words.length
        return words[index]

    if (newText = findWord(text, @getUserConfig(scopeName)))?
      return newText

    if scopeName in settings.get('defaultWordGroupExcludeScope')
      return null

    if (newText = findWord(text, @getDefaultConfig(scopeName)))?
      return newText

  flashRange: (range) ->
    marker = @editor.markBufferRange(range)
    decorateOptions = {type: 'highlight', class: 'toggle-flash'}
    @editor.decorateMarker(marker, decorateOptions)
    setTimeout ->
      marker.destroy()
    , settings.get('flashDurationMilliSeconds')

  toggleWord: (cursor, where) ->
    scopeNameAtCursor = @getScopeNameAtCursor(cursor)

    pattern = /(\b\w+\b)/g
    cursorPosition = cursor.getBufferPosition()
    scanRange = @editor.bufferRangeForBufferRow(cursorPosition.row)

    isValidTarget = (range) ->
      if where is 'here'
        range.containsPoint(cursorPosition)
      else
        range.end.isGreaterThanOrEqual(cursorPosition)

    @editor.scanInBufferRange pattern, scanRange, ({range, replace, matchText, stop, match}) =>
      if isValidTarget(range)
        for scopeName in [scopeNameAtCursor, '*']
          if (newText = @getWord(matchText, scopeName))?
            stop()
            newRange = replace(newText)
            newStart = newRange.start
            @flashRange(newRange) if range.start.isGreaterThan(cursorPosition)
            if (where in ['visit', 'here']) or newStart.isLessThan(cursorPosition)
              cursor.setBufferPosition(newStart)

            break

  # options
  # - where: ['here', 'there', 'visit']
  toggle: (where) ->
    @editor = atom.workspace.getActiveTextEditor()
    @editor.transact =>
      for cursor in @editor.getCursors()
        @toggleWord(cursor, where)
