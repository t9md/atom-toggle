const {it, fit, ffit, fffit, emitterEventPromise, beforeEach, afterEach} = require("./async-spec-helpers")

const path = require("path")
const fs = require("fs-plus")
const temp = require("temp")
const dedent = require("dedent")

const grammarForScopeName = name => atom.grammars.grammarForScopeName(name)

describe("toggle", function() {
  let editor
  const tempDirPath = fs.realpathSync(temp.mkdirSync("temp"))
  const dispatchCommand = command => atom.commands.dispatch(editor.element, command)

  const ensure = ({text, cursor, cursors}) => {
    expect(editor.getText()).toEqual(text)
    if (cursor) {
      expect(editor.getCursorBufferPosition()).toEqual(cursor)
    } else if (cursors) {
      expect(editor.getCursorBufferPositions()).toEqual(cursors)
    }
  }

  beforeEach(async () => {
    jasmine.attachToDOM(atom.workspace.getElement())
    editor = await atom.workspace.open()
    const activationPromise = atom.packages.activatePackage("toggle")
    dispatchCommand("toggle:here")
    await activationPromise
  })

  describe("toggle:here", () => {
    beforeEach(() => editor.setText("['yes', 'no']\nup, down\n"))

    it("toggle word under cursor", () => {
      editor.setCursorBufferPosition([0, 4])
      dispatchCommand("toggle:here")
      ensure({cursor: [0, 2], text: "['no', 'no']\nup, down\n"})

      editor.setCursorBufferPosition([0, 9])
      dispatchCommand("toggle:here")
      ensure({cursor: [0, 8], text: "['no', 'yes']\nup, down\n"})
    })

    it("support multiple cursor", () => {
      editor.setCursorBufferPosition([0, 4])
      editor.addCursorAtBufferPosition([1, 0])
      editor.addCursorAtBufferPosition([1, 4])
      dispatchCommand("toggle:here")
      ensure({
        cursors: [[0, 2], [1, 0], [1, 6]],
        text: "['no', 'no']\ndown, up\n",
      })
    })
  })

  describe("toggle:visit", () => {
    beforeEach(() => editor.setText("['yes', 'no']\nup, down\n"))

    it("toggle forwarding word and move cursor to start of toggled word", () => {
      editor.setCursorBufferPosition([0, 0])
      dispatchCommand("toggle:visit")
      ensure({cursor: [0, 2], text: "['no', 'no']\nup, down\n"})
    })
  })

  describe("toggle:there", () => {
    beforeEach(() => editor.setText("['yes', 'no']\nup, down\n"))

    it("toggle forwarding word and don't move cursor position", () => {
      editor.setCursorBufferPosition([0, 0])
      dispatchCommand("toggle:there")
      ensure({cursor: [0, 0], text: "['no', 'no']\nup, down\n"})
    })

    describe("when toggled word's start is less than cursor position", () =>
      it("move cursor to start of toggled word", () => {
        editor.setCursorBufferPosition([1, 7])
        dispatchCommand("toggle:there")
        ensure({cursor: [1, 4], text: "['yes', 'no']\nup, up\n"})
      }))
  })

  describe("[config] useDefaultWordGroup", () => {
    beforeEach(() => {
      editor.setText("['yes', 'no']\nup, down\n")
      atom.config.set("toggle.useDefaultWordGroup", false)
    })

    it("don't lookup default word group, so nothing happen", () => {
      editor.setCursorBufferPosition([1, 0])
      dispatchCommand("toggle:here")
      ensure({cursor: [1, 0], text: "['yes', 'no']\nup, down\n"})
    })
  })

  describe("scope specific setting", () => {
    beforeEach(async () => {
      await atom.packages.activatePackage("language-coffee-script")
      editor.setText("yes, no")
    })

    describe("[config] defaultWordGroupExcludeScope", () => {
      beforeEach(() => {
        atom.config.set("toggle.defaultWordGroupExcludeScope", ["source.coffee"])
      })

      it("doesn't lookup default word group, so nothing happen", () => {
        editor.setGrammar(grammarForScopeName("source.coffee"))
        editor.setCursorBufferPosition([0, 0])
        dispatchCommand("toggle:here")
        ensure({cursor: [0, 0], text: "yes, no"})
      })

      it("lookup default word group when scopen not matches to defaultWordGroupExcludeScope", () => {
        editor.setGrammar(grammarForScopeName("text.plain.null-grammar"))
        editor.setCursorBufferPosition([0, 0])
        dispatchCommand("toggle:here")
        ensure({cursor: [0, 0], text: "no, no"})
      })
    })
  })

  describe("toggle:open-config", () => {
    let configEditor, configPath

    beforeEach(() => {
      editor.setText("hello")
      atom.config.set("toggle.configPath", path.join(tempDirPath, "toggle.cson"))
      atom.commands.dispatch(atom.workspace.getElement(), "toggle:open-config")

      runs(() =>
        atom.workspace.onDidAddTextEditor(({textEditor}) => {
          configEditor = textEditor
        })
      )

      waitsFor(() => atom.workspace.getActiveTextEditor().getPath() === atom.config.get("toggle.configPath"))
    })

    it("open file specified by 'toggle.configPath'", () =>
      expect(configEditor.getPath()).toBe(atom.config.get("toggle.configPath")))

    it("automatically load user config on save", async () => {
      atom.workspace.getActivePane().activateItem(editor)
      editor.setCursorBufferPosition([0, 0])
      dispatchCommand("toggle:here")
      ensure({cursor: [0, 0], text: "hello"})

      configEditor.setText(dedent`
        '*': [
          ['hello', 'world']
        ]`)
      await configEditor.save()
      atom.workspace.getActivePane().activateItem(editor)
      dispatchCommand("toggle:here")
      ensure({cursor: [0, 0], text: "world"})
      dispatchCommand("toggle:here")
      ensure({cursor: [0, 0], text: "hello"})
    })

    describe("scope based word group", () => {
      beforeEach(async () => {
        atom.workspace.getActivePane().activateItem(editor)
        configEditor.setText(dedent`
          '*': [
            ['hello', 'world']
          ]
          'source.coffee': [
            ['coffee', 'tasty']
          ]`)
        await configEditor.save()
        await atom.packages.activatePackage("language-coffee-script")

        editor.setText("hello\ncoffee")
        editor.setCursorBufferPosition([0, 0])
        editor.addCursorAtBufferPosition([1, 0])
      })

      it("case: null grammar", () => {
        editor.setGrammar(grammarForScopeName("text.plain.null-grammar"))
        dispatchCommand("toggle:here")
        ensure({cursors: [[0, 0], [1, 0]], text: "world\ncoffee"})
      })

      it("case: coffee grammar", () => {
        editor.setGrammar(grammarForScopeName("source.coffee"))
        dispatchCommand("toggle:here")
        ensure({cursors: [[0, 0], [1, 0]], text: "world\ntasty"})
      })
    })
  })
})
