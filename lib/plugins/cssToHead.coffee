
exports['text/html'] = (req, res, document, next) ->
  head = document.querySelector 'head'
  if not head
    head = document.createElement 'head'
    document.documentElement.insertBefore head, document.documentElement.firstChild

  styles = document.querySelectorAll 'link[rel="stylesheet"], style'
  head.appendChild style for style in styles

  next document
