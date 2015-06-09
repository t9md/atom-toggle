{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'

Config =
  wordGroup:
    type: 'array'
    default: [
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
      ['this'  , '@']
      ['is'    , 'isnt']
      ['one'   , 'two'   , 'three']
    ]

module.exports =
  disposables: null
  config: Config

  activate: (state) ->
    @disposables = new CompositeDisposable

    @disposables.add atom.commands.add 'atom-workspace',
      'toggle:toggle': => @toggle()

  deactivate: ->
    @disposables.dispose()

  serialize: ->

  getWord: (word) ->
    wordGroup = atom.config.get('toggle.wordGroup')
    words = _.detect(wordGroup, (words) -> word in words)
    return null unless words
    index = words.indexOf(word)

    nextIndex = index + 1
    if nextIndex is words.length
      nextIndex = 0

    words[nextIndex]

  toggleWord: (cursor) ->
    range = cursor.getCurrentWordBufferRange()
    word = cursor.editor.getTextInBufferRange range
    newWord = @getWord word
    if newWord?
      cursor.editor.setTextInBufferRange(range, newWord)

  toggle: ->
    console.log 'called'
    return unless editor = atom.workspace.getActiveTextEditor()
    editor.transact =>
      for cursor in editor.getCursors()
        position = cursor.getBufferPosition()
        @toggleWord(cursor)
        cursor.setBufferPosition(position)
