combiner = require '../resource-combiner.coffee'

exports['text/html'] = (req, res, document, next) ->
  console.log 'cssToHead'
  head = document.querySelector 'head'
  if not head
    head = document.createElement 'head'
    document.documentElement.insertBefore head, document.documentElement.firstChild

  styles = document.querySelectorAll 'link[rel="stylesheet"]'
  href = combiner.combine
    resources: styles
    req: req
    contentType: 'text/css'
    prefix: 'css/'

  style.parentNode.removeChild(style) for style in styles

  style = document.createElement 'link'
  style.href = href
  style.rel = 'stylesheet'
  style.type = 'text/css'
  head.appendChild style

  next document
