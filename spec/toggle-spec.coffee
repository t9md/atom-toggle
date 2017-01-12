path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
# Main
# -------------------------
describe "toggle", ->
  [editor, editorElement, workspaceElement] = []
  tempDirPath = fs.realpathSync(temp.mkdirSync('temp'))
  dispatchCommand = (command) ->
    atom.commands.dispatch(editorElement, command)

  ensure = ({text, cursor, curosrs}) ->
    expect(editor.getText()).toEqual(text)
    switch
      when cursor?
        expect(editor.getCursorBufferPosition()).toEqual(cursor)
      when cursors?
        expect(editor.getCursorBufferPositions()).toEqual(cursors)

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = null

    waitsForPromise ->
      atom.workspace.open()

    runs ->
      jasmine.attachToDOM(workspaceElement)
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      activationPromise = atom.packages.activatePackage("toggle")
      # just for activation trigger
      dispatchCommand('toggle:here')

    waitsForPromise ->
      activationPromise

  describe "toggle:here", ->
    beforeEach ->
      editor.setText("['yes', 'no']\nup, down\n")

    it "toggle word under cursor", ->
      editor.setCursorBufferPosition([0, 4])
      dispatchCommand('toggle:here')
      ensure(cursor: [0, 2], text: "['no', 'no']\nup, down\n")

      editor.setCursorBufferPosition([0, 9])
      dispatchCommand('toggle:here')
      ensure(cursor: [0, 8], text: "['no', 'yes']\nup, down\n")

    it "support multiple cursor", ->
      editor.setCursorBufferPosition([0, 4])
      editor.addCursorAtBufferPosition([1, 0])
      editor.addCursorAtBufferPosition([1, 4])
      dispatchCommand('toggle:here')
      ensure
        cursors: [[0, 2], [1, 0], [1, 6]]
        text: "['no', 'no']\ndown, up\n"

  describe "toggle:visit", ->
    beforeEach ->
      editor.setText("['yes', 'no']\nup, down\n")

    it "toggle forwarding word and move cursor to start of toggled word", ->
      editor.setCursorBufferPosition([0, 0])
      dispatchCommand('toggle:visit')
      ensure(cursor: [0, 2], text: "['no', 'no']\nup, down\n")

  describe "toggle:there", ->
    beforeEach ->
      editor.setText("['yes', 'no']\nup, down\n")

    it "toggle forwarding word and don't move cursor position", ->
      editor.setCursorBufferPosition([0, 0])
      dispatchCommand('toggle:there')
      ensure(cursor: [0, 0], text: "['no', 'no']\nup, down\n")

    describe "when toggled word's start is less than cursor position", ->
      it "move cursor to start of toggled word", ->
        editor.setCursorBufferPosition([1, 7])
        dispatchCommand('toggle:there')
        ensure(cursor: [1, 4], text: "['yes', 'no']\nup, up\n")

  describe "[config] useDefaultWordGroup", ->
    beforeEach ->
      editor.setText("['yes', 'no']\nup, down\n")
      atom.config.set('toggle.useDefaultWordGroup', false)

    it "don't lookup default word group, so nothing happen", ->
      editor.setCursorBufferPosition([1, 0])
      dispatchCommand('toggle:here')
      ensure(cursor: [1, 0], text: "['yes', 'no']\nup, down\n")

  describe "scope specific setting", ->
    [coffeeGrammar, nullGrammar] = []
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-coffee-script')

      runs ->
        coffeeGrammar = atom.grammars.grammarForScopeName('source.coffee')
        nullGrammar = atom.grammars.grammarForScopeName('text.plain.null-grammar')
        editor.setText("yes, no")

    describe "[config] defaultWordGroupExcludeScope", ->
      beforeEach ->
        atom.config.set('toggle.defaultWordGroupExcludeScope', ['source.coffee'])

      it "don't lookup default word group, so nothing happen", ->
        editor.setGrammar(coffeeGrammar)
        editor.setCursorBufferPosition([0, 0])
        dispatchCommand('toggle:here')
        ensure(cursor: [0, 0], text: "yes, no")

      it "lookup default word group when scopen not matches to defaultWordGroupExcludeScope", ->
        editor.setGrammar(nullGrammar)
        editor.setCursorBufferPosition([0, 0])
        dispatchCommand('toggle:here')
        ensure(cursor: [0, 0], text: "no, no")

  describe "toggle:open-config", ->
    [configEditor, configPath] = []

    beforeEach ->
      editor.setText """
      hello
      """

      configPath = path.join(tempDirPath, "toggle.cson")
      atom.config.set('toggle.configPath', configPath)
      atom.commands.dispatch(workspaceElement, 'toggle:open-config')

      runs ->
        atom.workspace.onDidAddTextEditor ({textEditor}) ->
          configEditor = textEditor

      waitsFor ->
        atom.workspace.getActiveTextEditor().getPath() is atom.config.get('toggle.configPath')

    it "open file specified by 'toggle.configPath'", ->
      configEditor.getPath() is atom.config.get('toggle.configPath')

    it "automatically load user config on save", ->
      atom.workspace.getActivePane().activateItem(editor)
      editor.setCursorBufferPosition([0, 0])
      dispatchCommand('toggle:here')
      ensure(cursor: [0, 0], text: "hello")

      configEditor.setText """
      '*': [
        ['hello', 'world']
      ]
      """
      configEditor.save()
      atom.workspace.getActivePane().activateItem(editor)
      dispatchCommand('toggle:here')
      ensure(cursor: [0, 0], text: "world")
      dispatchCommand('toggle:here')
      ensure(cursor: [0, 0], text: "hello")

    describe "scope based word group", ->
      [coffeeGrammar, nullGrammar] = []

      beforeEach ->
        atom.workspace.getActivePane().activateItem(editor)
        configEditor.setText """
        '*': [
          ['hello', 'world']
        ]
        'source.coffee': [
          ['coffee', 'tasty']
        ]
        """
        configEditor.save()

        waitsForPromise ->
          atom.packages.activatePackage('language-coffee-script')

        runs ->
          coffeeGrammar = atom.grammars.grammarForScopeName('source.coffee')
          nullGrammar = atom.grammars.grammarForScopeName('text.plain.null-grammar')
          editor.setText("hello\ncoffee")
          editor.setCursorBufferPosition([0, 0])
          editor.addCursorAtBufferPosition([1, 0])

      it "case: null grammar", ->
        editor.setGrammar(nullGrammar)
        dispatchCommand('toggle:here')
        ensure(cursors: [[0, 0], [1, 0]], text: "world\ncoffee")

      it "case: coffee grammar", ->
        editor.setGrammar(coffeeGrammar)
        dispatchCommand('toggle:here')
        ensure(cursors: [[0, 0], [1, 0]], text: "world\ntasty")
