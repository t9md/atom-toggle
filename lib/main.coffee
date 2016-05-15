{CompositeDisposable} = require 'atom'
_    = require 'underscore-plus'
fs   = require 'fs-plus'
CSON = null

{inspect} = require 'util'
p = (args...) -> console.log inspect(args...)

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
    disposable = null
    atom.workspace.open(filePath).then (editor) =>
      unless fs.existsSync(filePath)
        # First time!
        editor.setText(userConfigTemplate)
        editor.save()

      disposable = editor.onDidSave =>
        @userWordGroup = @readConfig()
      editor.onDidDestroy ->
        disposable.dispose()

  getUserWordGroup: ->
    @userWordGroup ?= @readConfig()

  getUserWordGroupForScope: (scopeName) ->
    @getUserWordGroup()[scopeName] ? []

  getDefaultWordGroup: ->
    if settings.get('useDefaultWordGroup')
      @defaultWordGroup ?= require './word-group'
    else
      {}

  getDefaultWordGroupForScope: (scopeName) ->
    @getDefaultWordGroup()[scopeName] ? []

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

  getWord: (word, scopeName) ->
    findWord = (word, wordGroups) ->
      for wordGroup in wordGroups when (index = wordGroup.indexOf(word)) >= 0
        index += 1
        index = 0 if index >= wordGroup.length
        return wordGroup[index]

    if newWord = findWord(word, @getUserWordGroupForScope(scopeName))
      return newWord

    unless scopeName in settings.get('defaultWordGroupExcludeScope')
      if newWord = findWord(word, @getDefaultWordGroupForScope(scopeName))
        return newWord

  flashRange: (range) ->
    flashDisposable?.dispose()
    marker = @editor.markBufferRange(range)
    decorateOptions = {type: 'highlight', class: 'toggle-flash'}
    @editor.decorateMarker(marker, decorateOptions)

    timeout = settings.get('flashDurationMilliSeconds')
    setTimeout ->
      marker.destroy()
    , timeout

  toggleWord: (selection) ->
    cursor = selection.cursor
    originalPoint = cursor.getBufferPosition()
    selection.selectWord()

    text = selection.getText()
    for scopeName in [@getScopeNameAtCursor(cursor), '*']
      if (newText = @getWord(text, scopeName))?
        break

    p(newText)
    if newText?
      range = selection.insertText(newText)
      cursor.setBufferPosition(range.start)
      @flashRange(range)
    else
      # Restore cursor position.
      cursor.setBufferPosition(originalPoint)

  # options
  # - where: ['here']
  # - restoreCursor: [true, false]
  toggle: (options={}) ->
    @editor = atom.workspace.getActiveTextEditor()
    @editor.transact =>
      for selection in @editor.getSelections()
        @toggleWord(selection)
