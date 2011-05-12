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
    new Date value

getHeaderName = (headers, searchName) ->
  searchName = searchName.toLowerCase()
  for name, value of headers
    if name.toLowerCase() == searchName
      return name

getHeaderComponents = (value) ->
  value?.replace(/^\s*|\s*$/g, '')?.split(/\s*,\s*/)
