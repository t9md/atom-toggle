{CompositeDisposable} = require 'atom'
fs = require 'fs-plus'
CSON = null

settings = require './settings'
userWordGroupTemplate = """
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
  #   ['not'   , ''] # just remove `not`
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
    settings.notifyAndDelete('flashOnToggle', 'flashColor')
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

  getWord: (text, scopeName, {lookupDefaultWordGroup}) ->
    lookupDefaultWordGroup ?= false
    findWord = (text, setOfWords) ->
      for words in setOfWords when (index = words.indexOf(text)) >= 0
        return words[(index + 1) % words.length]

    if (newText = findWord(text, @getUserWordGroup(scopeName)))?
      return newText

    return unless lookupDefaultWordGroup

    if (newText = findWord(text, @getDefaultWordGroup(scopeName)))?
      return newText

  # Where: ['here', 'there', 'visit']
  toggle: (where) ->
    @editor = atom.workspace.getActiveTextEditor()
    @editor.transact =>
      @toggleWord(cursor, where) for cursor in @editor.getCursors()

  toggleWord: (cursor, where) ->
    pattern = /\b\w+\b/g
    cursorPosition = cursor.getBufferPosition()
    scanRange = @editor.bufferRangeForBufferRow(cursorPosition.row)
    scopeNameAtCursor = @getScopeNameAtCursor(cursor)
    scopeNames = [scopeNameAtCursor, '*']
    lookupDefaultWordGroup = scopeNameAtCursor not in settings.get('defaultWordGroupExcludeScope')

    @editor.scanInBufferRange pattern, scanRange, ({range, replace, matchText, stop, match}) =>
      return unless @isValidTarget(where, range, cursorPosition)
      for scopeName in scopeNames when (newText = @getWord(matchText, scopeName, {lookupDefaultWordGroup}))?
        stop()
        newRange = replace(newText)
        newStart = newRange.start
        @flashRange(newRange) if range.start.isGreaterThan(cursorPosition)
        if (where in ['visit', 'here']) or newStart.isLessThan(cursorPosition)
          cursor.setBufferPosition(newStart)
        break

  isValidTarget: (where, range, point) ->
    if where is 'here'
      range.containsPoint(point)
    else
      range.end.isGreaterThanOrEqual(point)

  flashRange: (range) ->
    marker = @editor.markBufferRange(range)
    @editor.decorateMarker(marker, {type: 'highlight', class: 'toggle-flash'})
    timeout = settings.get('flashDurationMilliSeconds')
    setTimeout ->
      marker.destroy()
    , timeout

  # Word group
  # -------------------------
  getUserWordGroupPath: ->
    fs.normalize(settings.get('configPath'))

  openUserConfig: ->
    filePath = @getUserWordGroupPath()
    disposable = null
    atom.workspace.open(filePath).then (editor) =>
      unless fs.existsSync(filePath)
        # First time!
        editor.setText(userWordGroupTemplate)
        editor.save()

      disposable = editor.onDidSave =>
        @userWordGroup = @readUserWordGroup()
      editor.onDidDestroy ->
        disposable.dispose()
        disposable = null

  getUserWordGroup: (scopeName) ->
    @userWordGroup ?= @readUserWordGroup()
    @userWordGroup[scopeName] ? []

  getDefaultWordGroup: (scopeName) ->
    if settings.get('useDefaultWordGroup')
      @defaultWordGroup ?= require './word-group'
      @defaultWordGroup[scopeName] ? []
    else
      []

  readUserWordGroup: ->
    filePath = @getUserWordGroupPath()
    return {} unless fs.existsSync(filePath)

    try
      CSON ?= require 'season'
      return CSON.readFileSync(filePath) or {}
    catch error
      atom.notifications.addError('[toggle] config file has error', detail: error.message)
    {}

  # Utils
  # -------------------------
  getScopeNameAtCursor: (cursor) ->
    scopeNames = (g.scopeName for g in atom.grammars.getGrammars())
    scopes = cursor.getScopeDescriptor().getScopesArray().reverse()
    return scope for scope in scopes when scope in scopeNames
