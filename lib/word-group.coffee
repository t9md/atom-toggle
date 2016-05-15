
wordGroups =
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
    ['+'     , '-']
    ['>'     , '<']
    ['>='    , '<=']
    ['&&'    , '||']
    ['&'     , '|']
    ['first' , 'last']
    ['=='    , '!=']
    ['enable', 'disable']
    ['enabled', 'disabled']
  ]
  'source.coffee': [
    ['this', '@']
    ['is'  , 'isnt']
    ['if'  , 'unless']
  ]

# Refer: https://github.com/zef/vim-cycle/blob/master/plugin/cycle.vim
webDevWordGroups = [
  ['<']
  ['>']
  ['div'       , 'p'          , 'span']
  ['max'       , 'min']
  ['ul'        , 'ol']
  ['class'     , 'id']
  ['px'        , '%'          , 'em']
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
wordGroups['text.html.basic']    = webDevWordGroups
wordGroups['text.html.gohtml']   = webDevWordGroups
wordGroups['text.html.jsp']      = webDevWordGroups
wordGroups['text.html.mustache'] = webDevWordGroups
wordGroups['text.html.erb']      = webDevWordGroups
wordGroups['text.html.ruby']     = webDevWordGroups

wordGroups['source.css']         = webDevWordGroups
wordGroups['source.css.less']    = webDevWordGroups
wordGroups['source.css.scss']    = webDevWordGroups

module.exports = wordGroups
