{jsdom} = require 'jsdom'

generateHandlers = (plugins) ->
  handlers = {}
  for plugin in plugins
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
  handlers

exports.create = (options) ->
  # Short circuit if no plugins were provided
  if not options.plugins?
    console.warn 'Performer specified without any plugins'
    return (res, req, next) -> next()

  # Register all of the MIME handlers in the passed plugins
  handlers = generateHandlers options.plugins

  contentConstructor =
    # Pass around a DOM rather than text content for the html operations
    'text/html': (content) ->
        jsdom content, null,
          features:
            FetchExternalResources: false,
            ProcessExternalResources: false,
            QuerySelector: true

  contentSerializer =
    'text/html': (content) ->
      content.innerHTML

  (req, res, next) ->
    writeHead = res.writeHead

    res.writeHead = (statusCode, reasonPhrase, headers) ->
      if arguments.length == 2
        headers = reasonPhrase
      headers or= res.headers

      contentType = headers?['Content-Type']?.split(';')[0]

      if handlers[contentType]
        # Divert the content stream for further processing
        buffer = []

        write = res.write
        res.write = (chunk, encoding) ->
          buffer.push chunk

        end = res.end
        res.end = (data, encoding) ->
          if data?
            buffer.push data

          # Generate the input content
          content = buffer.join ''
          if contentConstructor[contentType]
            content = contentConstructor[contentType] content

          # Run the plugins
          handlers[contentType] req, res, content, (content) ->
            # Convert back to text if necessary
            if contentSerializer[contentType]
              content = contentSerializer[contentType] content

            res.writeHead = writeHead
            res.write = write
            res.end = end

            headers['Content-Length'] = content.length

            # Send everything on the way
            res.writeHead statusCode, headers
            res.end content, encoding
      else
        res.writeHead = writeHead
        res.writeHead arguments...

    next()
