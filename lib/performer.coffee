
exports.performer = (options) ->
  handlers = {}

  # Register all of the MIME handlers in the passed plugins
  for plugin in options.plugins
    for mime, handler of plugin
      existingHandler = handlers[mime]

      # Chain multiple plugins on the same mime type
      handlers[mime] = if existingHandler
          do (mime, handler, existingHandler) ->
            (req, res, content, next) ->
              existingHandler req, res, content, (content) ->
                handler req, res, content, next
        else
          handler

  (req, res, next) ->

    next()
