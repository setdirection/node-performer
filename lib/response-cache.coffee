
# getResponseCacheInfo : Determines the expiration time for the passed headers
#
# @param res HTTP response object or Object mapping headers to value
#
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
      baseTime = if getHeader 'date'
          new Date getHeader 'date'
        else
          baseTime ? new Date()
      new Date baseTime.getTime() + parseInt(cacheControl['max-age'])*1000
    else
      expires = getHeader 'expires'
      expires and new Date expires
  etag = getHeader 'etag'
  lastModified = if lastModified = getHeader 'last-modified'
    new Date lastModified

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

getHeaderName = (headers, searchName) ->
  searchName = searchName.toLowerCase()
  for name, value of headers
    if name.toLowerCase() == searchName
      return name

getHeaderComponents = (value) ->
  value?.replace(/^\s*|\s*$/g, '')?.split(/\s*,\s*/)
