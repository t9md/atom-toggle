wordGroup =
  '*': [
    ['yes'   , 'no']
    ['up'    , 'down']
    ['right' , 'left']
    ['true'  , 'false']
    ['high'  , 'low']
    ['column', 'row']
    ['and'   , 'or']
    ['on'    , 'off']
    ['in'    , 'out']
    ['first' , 'last']
    ['enable', 'disable']
    ['enabled', 'disabled']
    ['before', 'after']
  ]
  'source.coffee': [
    ['is'  , 'isnt']
    ['if'  , 'unless']
  ]

# Refer: https://github.com/zef/vim-cycle/blob/master/plugin/cycle.vim
wordGroupForWeb = [
  ['div'       , 'p'          , 'span']
  ['max'       , 'min']
  ['ul'        , 'ol']
  ['class'     , 'id']
  ['px'        , 'em']
  ['left'      , 'right']
  ['top'       , 'bottom']
  ['margin'    , 'padding']
  ['height'    , 'width']
  ['absolute'  , 'relative']
  ['h1'        , 'h2'         , 'h3']
  ['png'       , 'jpg'        , 'gif']
  ['linear'    , 'radial']
  ['horizontal', 'vertical']
  ['show'      , 'hide']
  ['mouseover' , 'mouseout']
  ['mouseenter', 'mouseleave']
  ['add'       , 'remove']
  ['up'        , 'down']
  ['before'    , 'after']
  ['slow'      , 'fast']
  ['small'     , 'large']
  ['even'      , 'odd']
  ['inside'    , 'outside']
  ['push'      , 'pull']
]

wordGroup['text.html.basic']    = wordGroupForWeb
wordGroup['text.html.gohtml']   = wordGroupForWeb
wordGroup['text.html.jsp']      = wordGroupForWeb
wordGroup['text.html.mustache'] = wordGroupForWeb
wordGroup['text.html.erb']      = wordGroupForWeb
wordGroup['text.html.ruby']     = wordGroupForWeb
wordGroup['source.css']         = wordGroupForWeb
wordGroup['source.css.less']    = wordGroupForWeb
wordGroup['source.css.scss']    = wordGroupForWeb

module.exports = wordGroup
