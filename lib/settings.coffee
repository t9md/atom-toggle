path = require 'path'
class Settings
  constructor: (@scope, @config) ->

  notifyAndDelete: (params...) ->
    paramsToDelete = (param for param in params when @has(param))
    return if paramsToDelete.length is 0

    content = [
      "#{@scope}: Config options deprecated.  ",
      "Automatically removed from your `connfig.cson`  "
    ]
    for param in paramsToDelete
      @delete(param)
      content.push "- `#{param}`"
    atom.notifications.addWarning content.join("\n"), dismissable: true

  notifyAndRename: (oldName, newName) ->
    return unless @has(oldName)

    @set(newName, @get(oldName))
    @delete(oldName)
    content = [
      "#{@scope}: Config options renamed.  ",
      "Automatically renamed in your `connfig.cson`  "
      " - `#{oldName}` to #{newName}"
    ]
    atom.notifications.addWarning content.join("\n"), dismissable: true

  has: (param) ->
    param of atom.config.get(@scope)

  delete: (param) ->
    @set(param, undefined)

  get: (param) ->
    atom.config.get "#{@scope}.#{param}"

  set: (param, value) ->
    atom.config.set "#{@scope}.#{param}", value

module.exports = new Settings 'toggle',
  configPath:
    order: 1
    type: 'string'
    default: path.join(atom.getConfigDirPath(), 'toggle.cson')
    description: 'filePath for user word group'
  useDefaultWordGroup:
    order: 2
    type: 'boolean'
    default: true
  defaultWordGroupExcludeScope:
    order: 3
    type: 'array'
    default: []
    items:
      type: 'string'
    description: 'Default wordGrop is not used for scope in this list'
  flashDurationMilliSeconds:
    order: 12
    type: 'integer'
    default: 150
    description: "Duration for flash"
