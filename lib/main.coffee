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

readCSON = (filePath) ->
  return {} unless fs.existsSync(filePath)

  try
    CSON ?= require 'season'
    return CSON.readFileSync(filePath) or {}
  catch error
    atom.notifications.addError('[toggle] config file has error', detail: error.message)
  {}

getScopeNameForCursor = (cursor) ->
  scopeNames = (grammar.scopeName for grammar in atom.grammars.getGrammars())
  scopes = cursor.getScopeDescriptor().getScopesArray()
  for scope in scopes by -1 when scope in scopeNames
    return scope
  null

flashRange = (editor, range, options) ->
  marker = editor.markBufferRange(range)
  editor.decorateMarker(marker, type: 'highlight', class: options.class)
  setTimeout ->
    marker.destroy()
  , options.timeout

module.exports =
  config: settings.config
  userWordGroupPath: null
  defaultWordGroup: null

  activate: (state) ->
    deprecatedConfigParams = ['flashOnToggle', 'flashColor', 'flashDurationMilliSeconds']
    settings.notifyAndDelete(deprecatedConfigParams...)

    @defaultWordGroup = require './word-group'

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor:not([mini])',
      'toggle:here': => @toggle('here')
      'toggle:visit': => @toggle('visit')
      'toggle:there': => @toggle('there')

    @subscriptions.add atom.commands.add 'atom-workspace',
      'toggle:open-config': => @openUserConfig()

    @subscriptions.add settings.observe 'configPath', (filePath) =>
      @userWordGroupPath = fs.normalize(filePath)

  deactivate: ->
    @subscriptions.dispose()
    [@subscriptions, @defaultWordGroup] = []

  getWord: (text, scopeName, {lookupDefaultWordGroup}) ->
    wordGroups = []
    wordGroups.push(@getUserWordGroupForScope(scopeName)...)
    if lookupDefaultWordGroup and (scopeName of @defaultWordGroup)
      wordGroups.push(@defaultWordGroup[scopeName]...)

    for wordGroup in wordGroups when (index = wordGroup.indexOf(text)) >= 0
      return wordGroup[(index + 1) % wordGroup.length]
    return null

  # Where: ['here', 'there', 'visit']
  toggle: (where) ->
    @editor = atom.workspace.getActiveTextEditor()
    @editor.transact =>
      for cursor in @editor.getCursors()
        @toggleWord(cursor, where)

  toggleWord: (cursor, where) ->
    cursorPosition = cursor.getBufferPosition()
    scopeNameForCursor = getScopeNameForCursor(cursor)
    scopeNames = [scopeNameForCursor, '*']
    lookupDefaultWordGroup = settings.get('useDefaultWordGroup') and
      (scopeNameForCursor not in settings.get('defaultWordGroupExcludeScope'))

    pattern = /\b\w+\b/g
    scanRange = @editor.bufferRangeForBufferRow(cursorPosition.row)
    @editor.scanInBufferRange pattern, scanRange, ({range, replace, matchText, stop}) =>
      if where is 'here'
        return unless range.containsPoint(cursorPosition)
      else
        return unless range.end.isGreaterThanOrEqual(cursorPosition)

      for scopeName in scopeNames
        newText = @getWord(matchText, scopeName, {lookupDefaultWordGroup})
        if newText?
          stop()
          flashRange(@editor, replace(newText), class: 'toggle-flash', timeout: 1000)
          if (where in ['visit', 'here']) or range.start.isLessThan(cursorPosition)
            cursor.setBufferPosition(range.start)
          break

  # Word group
  # -------------------------
  openUserConfig: ->
    isInitialOpen = not fs.existsSync(@userWordGroupPath)
    atom.workspace.open(@userWordGroupPath, searchAllPanes: true).then (editor) =>
      if isInitialOpen
        editor.setText(userWordGroupTemplate)
        editor.save()

      disposable = editor.onDidSave(@loadUserWordGroup.bind(this))
      editor.onDidDestroy -> disposable.dispose()

  getUserWordGroupForScope: (scopeName) ->
    @loadUserWordGroup() unless @userWordGroup?
    @userWordGroup[scopeName] ? []

  loadUserWordGroup: ->
    @userWordGroup = readCSON(@userWordGroupPath)
