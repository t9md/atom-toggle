{CompositeDisposable} = require 'atom'
path = require 'path'
_    = require 'underscore-plus'
CSON = require 'season'
fs   = require 'fs-plus'

wordGroup = require './word-group'


Config =
  configPath:
    order: 1
    type: 'string'
    default: path.join(atom.getConfigDirPath(), 'toggle.cson')
    description: 'filePath for words definitions'

module.exports =
  disposables: null
  scopedWordGroup: {}
  config: Config
  hooks: {}

  activate: (state) ->
    @disposables = new CompositeDisposable

    @disposables.add atom.commands.add 'atom-workspace',
      'toggle:toggle': => @toggle()
      'toggle:debug':  => @debug()
      'toggle:reload': => @readConfig()

    @registerWords = (words) =>
      @scopedWordGroup = words

    @registerHook = (scope, hook) =>
      @hooks[scope] = hook

  deactivate: ->
    @disposables.dispose()

  serialize: ->

  debug: ->
    console.log @scopedWordGroup

  detectCursorScope: (cursor) ->
    supportedScopeNames = _.pluck(atom.grammars.getGrammars(), 'scopeName')
    scopesArray = cursor.getScopeDescriptor().getScopesArray()
    scope = _.detect scopesArray.reverse(), (scope) ->
      scope in supportedScopeNames
    scope


  isExistsHook: (scope) ->
    @hooks[scope]

  readConfig: ->
    filePath = fs.normalize(atom.config.get('toggle.configPath'))

    if fs.existsSync filePath
      config = CSON.readFileSync(filePath)
    else
      message = "[toggle] file #{filePath} not exists"
      options = {}
        # detail: error.message
      atom.notifications.addError message, options

  getWord: (word, scope) ->
    if @isExistsHook(scope)
      event =
        # bufferLine: cursor.getCurrentBufferLine()
        word: word

      newWord = @hooks[scope](event)
      return newWord if newWord?

    wordGroup = []
    if @scopedWordGroup[scope]
      wordGroup = wordGroup.concat @scopedWordGroup[scope]
    wordGroup = wordGroup.concat atom.config.get('toggle.wordGroup')

    words = _.detect(wordGroup, (words) -> word in words)
    return null unless words
    index = words.indexOf(word)

    nextIndex = index + 1
    if nextIndex is words.length
      nextIndex = 0

  toggleWord: (cursor) ->

    range = cursor.getCurrentWordBufferRange()
    word = cursor.editor.getTextInBufferRange range
    scope = @detectCursorScope(cursor)
    newWord = @getWord word, scope
    if newWord?
      cursor.editor.setTextInBufferRange(range, newWord)

  toggle: ->
    return unless editor = atom.workspace.getActiveTextEditor()
    editor.transact =>
      for cursor in editor.getCursors()
        position = cursor.getBufferPosition()
        @toggleWord(cursor)
        cursor.setBufferPosition(position)
