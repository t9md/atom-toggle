path = require 'path'
class Settings
  constructor: (@scope, @config) ->

  get: (param) ->
    atom.config.get "#{@scope}.#{param}"

  set: (param, value) ->
    atom.config.set "#{@scope}.#{param}", value

module.exports = new Settings 'toggle',
  configPath:
    order: 1
    type: 'string'
    default: path.join(atom.getConfigDirPath(), 'toggle.cson')
    description: 'filePath for words definitions'
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
  flashOnToggle:
    order: 11
    type: 'boolean'
    default: true
    description: "Flash toggled word"
  flashDurationMilliSeconds:
    order: 12
    type: 'integer'
    default: 150
    description: "Duration for flash"
