path = require 'path'
inferType = (value) ->
  switch
    when Number.isInteger(value) then 'integer'
    when typeof(value) is 'boolean' then 'boolean'
    when typeof(value) is 'string' then 'string'
    when Array.isArray(value) then 'array'

class Settings
  constructor: (@scope, @config) ->
    # Automatically infer and inject `type` of each config parameter.
    # skip if value which aleady have `type` field.
    for key in Object.keys(@config)
      unless (value = @config[key]).type?
        value.type = inferType(value.default)

    # [CAUTION] injecting order propety to set order shown at setting-view MUST-COME-LAST.
    for name, i in Object.keys(@config)
      @config[name].order = i

  get: (param) ->
    atom.config.get "#{@scope}.#{param}"

  set: (param, value) ->
    atom.config.set "#{@scope}.#{param}", value

  has: (param) ->
    param of atom.config.get(@scope)

  delete: (param) ->
    @set(param, undefined)

  toggle: (param) ->
    @set(param, not @get(param))

  observe: (param, fn) ->
    atom.config.observe("#{@scope}.#{param}", fn)

  onDidChange: (param, fn) ->
    atom.config.onDidChange("#{@scope}.#{param}", fn)

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

module.exports = new Settings 'toggle',
  configPath:
    default: path.join(atom.getConfigDirPath(), 'toggle.cson')
    description: 'filePath for user word group'
  useDefaultWordGroup:
    default: true
  defaultWordGroupExcludeScope:
    default: []
    items:
      type: 'string'
    description: 'Default wordGrop is not used for scope in this list'
