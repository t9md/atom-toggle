# Helpers
# -------------------------
dispatchCommand = (target, command) ->
  atom.commands.dispatch(target, command)

# Main
# -------------------------
describe "toggle", ->
  [editor, editorElement, workspaceElement] = []
  ensure = ({text, cursor, curosrs}) ->
    expect(editor.getText()).toEqual(text)
    if cursor?
      expect(editor.getCursorBufferPosition()).toEqual(cursor)
    else if cursors?
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
      dispatchCommand(editorElement, 'toggle:here')

    waitsForPromise ->
      activationPromise

  describe "toggle:here", ->
    beforeEach ->
      editor.setText """
      ['yes', 'no']
      up, down\n
      """

    it "toggle word under cursor", ->
      editor.setCursorBufferPosition([0, 4])
      dispatchCommand(editorElement, 'toggle:here')
      ensure
        cursor: [0, 2]
        text: """
        ['no', 'no']
        up, down\n
        """
      editor.setCursorBufferPosition([0, 9])
      dispatchCommand(editorElement, 'toggle:here')
      ensure
        cursor: [0, 8]
        text: """
        ['no', 'yes']
        up, down\n
        """
    it "support multiple cursor", ->
      editor.setCursorBufferPosition([0, 4])
      editor.addCursorAtBufferPosition([1, 0])
      editor.addCursorAtBufferPosition([1, 4])
      dispatchCommand(editorElement, 'toggle:here')
      ensure
        cursors: [[0, 2], [1, 0], [1, 6]]
        text: """
        ['no', 'no']
        down, up\n
        """

  describe "toggle:visit", ->
    beforeEach ->
      editor.setText """
      ['yes', 'no']
      up, down\n
      """

    it "toggle forwarding word and move cursor to start of toggled", ->
      editor.setCursorBufferPosition([0, 0])
      dispatchCommand(editorElement, 'toggle:visit')
      ensure
        cursor: [0, 2]
        text: """
        ['no', 'no']
        up, down\n
        """

  describe "toggle:there", ->
    beforeEach ->
      editor.setText """
      ['yes', 'no']
      up, down\n
      """

    it "toggle forwarding word and don't move cursor position", ->
      editor.setCursorBufferPosition([0, 0])
      dispatchCommand(editorElement, 'toggle:there')
      ensure
        cursor: [0, 0]
        text: """
        ['no', 'no']
        up, down\n
        """

    it "but when word start postion is less than cursor it move start of word after toggle", ->
      editor.setCursorBufferPosition([1, 7])
      dispatchCommand(editorElement, 'toggle:there')
      ensure
        cursor: [1, 4]
        text: """
        ['yes', 'no']
        up, up\n
        """
