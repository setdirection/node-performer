combiner = require '../resource-combiner.coffee'

exports['text/html'] = (req, res, document, next) ->
  console.log 'jsCombine'
  body = document.querySelector 'body' or document.documentElement

  scripts = document.querySelectorAll 'script[src]'
  href = combiner.combine
    resources: {href: script.src} for script in scripts
    req: req
    separator: '\n;'
    contentType: 'application/javascript'
    prefix: 'js/'

  script.parentNode.removeChild(script) for script in scripts

  script = document.createElement 'script'
  script.src = href
  script.type = 'application/javascript'
  body.appendChild script

  next document
