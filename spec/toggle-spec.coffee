# Main
# -------------------------
describe "toggle", ->
  [editor, editorElement, workspaceElement] = []
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

    it "toggle forwarding word and move cursor to start of toggled", ->
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

    it "but when word start postion is less than cursor it move start of word after toggle", ->
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

  # describe "[config] defaultWordGroupExcludeScope", ->
  #   beforeEach ->
  #     dispatchCommand('toggle:open-config')
  #
  #     waitsForPromise ->
  #     # editor.setText """
  #     # ['yes', 'no']
  #     # up, down\n
  #     # """
  #     # atom.config.set('toggle.useDefaultWordGroup', false)
  # # describe "toggle:open-config", ->
