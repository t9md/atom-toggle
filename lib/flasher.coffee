module.exports =
class Flasher
  @flashers: []
  constructor: (@editor, @marker) ->

  flash: ({class: className, duration, persist}) ->
    @decoration = @editor.decorateMarker @marker,
      type: 'highlight'
      class: className

    return if persist

    setTimeout  =>
      @decoration.getMarker().destroy()
    , duration

  @register: (editor, marker) ->
    @flashers.push new this(editor, marker)

  @flash: (options) ->
    for flasher in @flashers
      flasher.flash(options)
    @flashers = []
