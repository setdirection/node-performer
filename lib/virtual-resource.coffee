resources = {}
count = 0

exports.create = ({content, contentType, prefix, path, headers}) ->
  resource = {
    content
    contentType
    modified: new Date()
    headers
    path: (prefix ? '') + (path ? count)
  }
  count++
  resources[resource.path] = resource
  resource.path

exports.middleware = (options) ->
  contentPath = options?.contentPath ? '/virtual/'

  (req, res, next) ->
    # Anything that starts with the content path is a potential resource
    if req.url.indexOf(contentPath) == 0
      resource = resources[req.url.substring contentPath.length]
      if not resource
        return next()

      sendContent = ->
        res.setHeader 'Content-Type', resource.contentType
        res.setHeader 'Content-Length', resource.content.length
        res.setHeader 'ETag', resource.modified.getTime() # WARN: This will need to be redone using md5 or similar if there are multiple servers
        res.setHeader 'Last-Modified', resource.modified.toUTCString()
        res.setHeader header, value for header, value of resource.headers
        res.end resource.content

      if typeof resource.content == 'function'
        resource.content (content) ->
          resource.content = content
          sendContent()
      else
        sendContent()
    else
      next()
