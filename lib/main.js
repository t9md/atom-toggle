const {CompositeDisposable} = require("atom")
const fs = require("fs-plus")
const path = require("path")
const CSON = require("season")
DEFAULT_WORD_GROUP = require("./word-group")

const CONFIG_TEMPLATE = `\
# Each word must match reglar expression '\w+'.
# So follwoing settings is invalid.
# e.g-1) both '<' and '>' not match '\w+'
#  ['<', '>']
#
# e.g-2) OK(this -> @), NG(@ -> this) \`@\` not match '\w+'
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
#   ['not'   , ''] # just remove \`not\`
#   ['on'    , 'off']
#   ['in'    , 'out']
#   ['one'   , 'two'   , 'three']
# ],
# 'source.coffee': [
#   ['is'  , 'isnt']
#   ['if'  , 'unless']
# ]\
`

function readCSON(filePath) {
  let result
  if (fs.existsSync(filePath)) {
    try {
      result = CSON.readFileSync(filePath)
    } catch (error) {
      atom.notifications.addError("[toggle] config file has error", {detail: error.message})
    }
  }
  return typeof result === "object" ? result : {}
}

function getScopeNameForCursor(cursor) {
  const scopeNames = atom.grammars.getGrammars().map(grammar => grammar.scopeName)
  const scopes = cursor.getScopeDescriptor().getScopesArray()
  return scopes.reverse().find(scope => scopeNames.includes(scope))
}

function flashRange(editor, range, options) {
  const marker = editor.markBufferRange(range)
  editor.decorateMarker(marker, {type: "highlight", class: options.class})
  setTimeout(() => marker.destroy(), options.timeout)
}

const CONFIG = {
  configPath: {
    order: 0,
    type: "string",
    default: path.join(atom.getConfigDirPath(), "toggle.cson"),
    description: "filePath for user word group",
  },
  useDefaultWordGroup: {
    order: 1,
    type: "boolean",
    default: true,
  },
  defaultWordGroupExcludeScope: {
    order: 2,
    type: "array",
    default: [],
    items: {
      type: "string",
    },
    description: "Default wordGrop is not used for scope in this list",
  },
}

module.exports = {
  config: CONFIG,

  activate() {
    const toggle = this.toggle.bind(this)

    this.subscriptions = new CompositeDisposable(
      atom.commands.add("atom-text-editor:not([mini])", {
        "toggle:here"() {
          toggle(this, "here")
        },
        "toggle:visit"() {
          toggle(this, "visit")
        },
        "toggle:there"() {
          toggle(this, "there")
        },
      }),
      atom.commands.add("atom-workspace", {
        "toggle:open-config": () => this.openUserConfig(),
      }),
      atom.config.observe("toggle.configPath", filePath => {
        this.userConfigPath = fs.normalize(filePath)
      })
    )
  },

  deactivate() {
    this.subscriptions.dispose()
  },

  getNextWord(currentWord, scopeName, {lookupDefaultWordGroup}) {
    const wordGroups = []

    if (scopeName in this.userWordGroup) {
      wordGroups.push(...this.userWordGroup[scopeName])
    }

    if (lookupDefaultWordGroup && scopeName in DEFAULT_WORD_GROUP) {
      wordGroups.push(...DEFAULT_WORD_GROUP[scopeName])
    }

    for (const words of wordGroups) {
      const index = words.indexOf(currentWord)
      if (index >= 0) {
        return words[(index + 1) % words.length]
      }
    }
  },

  // Where: ['here', 'there', 'visit']
  toggle(editorElement, where) {
    const editor = editorElement.getModel()
    if (!this.userWordGroup) this.loadUserConfig()

    editor.transact(() => {
      editor.getCursors().forEach(cursor => {
        this.toggleWord(cursor, where)
      })
    })
  },

  toggleWord(cursor, where) {
    const editor = cursor.editor
    const cursorPosition = cursor.getBufferPosition()
    const scopeNameForCursor = getScopeNameForCursor(cursor)
    const scopeNames = [scopeNameForCursor, "*"].filter(v => v)
    const lookupDefaultWordGroup =
      atom.config.get("toggle.useDefaultWordGroup") &&
      !atom.config.get("toggle.defaultWordGroupExcludeScope").includes(scopeNameForCursor)

    const scanRange = editor.bufferRangeForBufferRow(cursorPosition.row)
    editor.scanInBufferRange(/\b\w+\b/g, scanRange, ({range, replace, matchText, stop}) => {
      if (where === "here") {
        if (!range.containsPoint(cursorPosition)) return
      } else {
        if (range.end.isLessThan(cursorPosition)) return
      }
      for (const scopeName of scopeNames) {
        const nextWord = this.getNextWord(matchText, scopeName, {lookupDefaultWordGroup})
        if (nextWord != null) {
          stop()

          const newTextRange = replace(nextWord)
          flashRange(editor, newTextRange, {class: "toggle-flash", timeout: 1000})
          if (["visit", "here"].includes(where) || range.start.isLessThan(cursorPosition)) {
            cursor.setBufferPosition(range.start)
          }
          break
        }
      }
    })
  },

  openUserConfig() {
    atom.workspace.open(this.userConfigPath, {searchAllPanes: true}).then(editor => {
      if (!fs.existsSync(this.userConfigPath)) {
        editor.setText(CONFIG_TEMPLATE)
        editor.save()
      }

      const disposable = editor.onDidSave(() => this.loadUserConfig())
      editor.onDidDestroy(() => disposable.dispose())
    })
  },

  loadUserConfig() {
    this.userWordGroup = readCSON(this.userConfigPath)
  },
}
