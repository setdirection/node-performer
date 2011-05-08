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

getHeaderName = (headers, searchName) ->
  searchName = searchName.toLowerCase()
  for name, value of headers
    if name.toLowerCase() == searchName
      return name

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
    headerInfo = undefined
    buffer = undefined

    writeHead = res.writeHead
    res.writeHead = (statusCode, reasonPhrase, headers) ->
      # Since we are not setting up the underlying header structures until later we may be called multiple
      # times so short circuit multiple exec
      if headerInfo
        return

      headerInfo =
        statusCode: statusCode
        headers: headers ? reasonPhrase ? @_headers ? {}
        contentType: headers?[getHeaderName headers, 'content-type']?.split(';')[0]
        handler: handlers[contentType]

      if headerInfo.handler
        buffer = []
      else
        writeHead.apply @, arguments

    write = res.write
    res.write = (chunk, encoding) ->
      if not headerInfo
        @_implicitHeader()

      if buffer
        buffer.push chunk
      else
        write.call @, chunk, encoding

    end = res.end
    res.end = (data, encoding) ->
      if not headerInfo
        @_implicitHeader()

      if buffer
        if data?
          buffer.push data

        # Generate the input content
        content = buffer.join ''
        if contentConstructor[headerInfo.contentType]
          content = contentConstructor[headerInfo.contentType] content

        # Run the plugins
        headerInfo.handler req, @, content, (content) ->
          # Convert back to text if necessary
          if contentSerializer[headerInfo.contentType]
            content = contentSerializer[headerInfo.contentType] content

          # Finally convert to a buffer to make sure that we have the byte length in the current encoding,
          # rather than the character length that the string length would return
          if typeof content == 'string'
            content = new Buffer content, encoding
          headerInfo.headers[getHeaderName headerInfo.headers, 'content-length'] = content.length

          # Send everything on the way
          writeHead.call res, headerInfo.statusCode, headerInfo.headers
          write.call res, content
          end.call res
      else
        end.call @, data, encoding

    next()
