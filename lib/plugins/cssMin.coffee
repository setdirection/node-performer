{cssmin} = require 'cssmin'

exports['text/css'] = (req, res, content, next) ->
  next cssmin content
