cache = {}

NOT_MODIFIED = 304

exports.create = ->
  (req, res, next) ->
    head = undefined
    headerInfo = undefined
    data = []

    if cacheEntry = cache[req.url]
      res.writeHead cacheEntry.head.statusCode, cacheEntry.head.headers
      for value in cacheEntry.data
        res.write value
      res.end()
      return

    writeHead = res.writeHead
    res.writeHead = (statusCode, reasonPhrase, headers) ->
      # If the cache response is not modified, ignore this whole mess
      if statusCode != NOT_MODIFIED
        headers = headers ? reasonPhrase ? @_headers ? {}
        headerInfo = exports.getResponseCacheInfo headers

        head = {statusCode, headers}

      writeHead.apply @, arguments

    write = res.write
    res.write = (chunk, encoding) ->
      write.apply @, arguments

      # Tail call, write header should have been called by now
      if headerInfo
        data.push if encoding then new Buffer chunk, encoding else chunk

    end = res.end
    res.end = (chunk, encoding) ->
      chunkCount = data.length
      end.apply @, arguments

      # Tail call, write header should have been called by now
      if headerInfo
        if chunk and chunkCount == data.length    # Output data if we have it and it hasn't been written already
          data.push if encoding then new Buffer chunk, encoding else chunk
        cache[req.url] = {
          url: req.url
          head
          headerInfo
          data
        }

    next()

exports.shouldSendResponse = (req, etag, lastModified) ->
  etagIn = (field) ->
    for tag in field
      if tag == '*' or ~tag.indexOf etag
        return true
    false

  cacheInfo = exports.getRequestCacheInfo req
  if cacheInfo
    # Check the etag
    etagMatch = if cacheInfo.match?
        etagIn cacheInfo.match
      else if cacheInfo.noMatch?
        not etagIn cacheInfo.noMatch
      else
        true

    # Check the modified date
    lastModified = lastModified.getTime?() ? lastModified
    timeMatch = if cacheInfo.modifiedSince?
        lastModified > cacheInfo.modifiedSince.getTime()
      else if cacheInfo.unmodifiedSince?
        lastModified < cacheInfo.unmodifiedSince.getTime()
      else
        true

    etagMatch and timeMatch
  else
    true

# getRequestCacheInfo : Determines the cache parameters for the given request or header set
#
# @param req HTTP request object or header object
exports.getRequestCacheInfo = (req, baseTime) ->
  headers = req.headers ? req
  getHeader = (name) -> headers[getHeaderName headers, name]

  ret =
    match: parseETag getHeader 'If-Match'
    noMatch: parseETag getHeader 'If-None-Match'
    modifiedSince: parseDate getHeader 'If-Modified-Since'
    unmodifiedSince: parseDate getHeader 'If-Unmodified-Since'
  if ret.match or ret.noMatch or ret.modifiedSince or ret.unmodifiedSince
    ret

# getResponseCacheInfo : Determines the cache parameters for a given response or header set
#
# @param res HTTP response object or Object mapping headers to value
exports.getResponseCacheInfo = (res, baseTime) ->
  getHeader = if res.getHeader
      (header) -> res.getHeader header
    else
      (header) -> res[getHeaderName res, header]

  cacheControl = parseHeader getHeader 'cache-control'
  pragma = parseHeader getHeader 'pragma'

  # Any no-cache directives prevent any operations
  if cacheControl['no-cache'] or pragma['no-cache']
    return

  expireTime = if cacheControl['max-age']
      baseTime = parseDate(getHeader('date')) ? baseTime ? new Date()
      new Date baseTime.getTime() + parseInt(cacheControl['max-age'])*1000
    else
      parseDate getHeader 'expires'
  etag = getHeader 'etag'
  lastModified = parseDate getHeader 'last-modified'

  if etag or expireTime or lastModified
    expires: expireTime
    etag: etag
    lastModified: lastModified

parseHeader = (value) ->
  components = getHeaderComponents value
  ret = {}
  for component in components ? []
    kv = component.split '='
    ret[kv[0].toLowerCase()] = kv[1] or true
  ret
parseETag = (value) ->
  re = /(\*|(?:W\/)?\".*?\")\s*,?\s*/g
  value = value?.replace(/^\s*|\s*$/g, '')
  ret = while match = re.exec value
    match[1]
  if ret.length
    ret
parseDate = (value) ->
  if value
    value = Date.parse value
    if isNaN value
      value = 0

    new Date value

getHeaderName = (headers, searchName) ->
  searchName = searchName.toLowerCase()
  for name, value of headers
    if name.toLowerCase() == searchName
      return name

getHeaderComponents = (value) ->
  value?.replace(/^\s*|\s*$/g, '')?.split(/\s*,\s*/)
