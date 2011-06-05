responseCache = require './response-cache.coffee'
resourceRequest = require './resource-request.coffee'
crypto = require 'crypto'
redis = require 'redis'

client = undefined    # Redis client, created when the middleware is created
contentPath = '/virtual/'

idResourceCache = {}
pathResourceCache = {}

HREF_PREFIX = 'href_'
HREF_PREFIX_LEN = HREF_PREFIX.length

externalResourceCache =
  store: ({path, prefix, separator, contentType, root, hrefs}) ->
    separator = separator ? ''
    root = root ? ''
    info = {
      path
      prefix
      separator
      contentType
      root
    }

    # Flatten the array into hash components
    for i in [0...hrefs.length]
      info[HREF_PREFIX + i] = hrefs[i]

    client?.hmset path, info
  load: (path, callback) ->
    client?.hgetall path, (err, obj) ->
      if err or not obj.path
        console.error "Failed to retrieve #{path} from redis instance", err
        callback()
      else
        resource = {
          root: {}
          resources: []
        }
        for key, value of obj
          if key.indexOf(HREF_PREFIX) == 0
            resource.resources[parseInt key.substring HREF_PREFIX_LEN] = { href: value }
          else
            resource[key] = value
        callback resource

checkComplete = (resource) ->
  # Determine if there are any incomplete operations
  for content in resource.content
    if not content.complete
      return false

  resource.content = new Buffer (content.data for content in resource.content).join(''), 'utf8'

  for deferred in resource.deferred
    deferred resource.content

  # Clear the deferred list so future requests will be handled directly
  resource.deferred = undefined

# TODO : Implement cache invalidation on a periodic basis here
exports.combine = ({resources, req, root, separator, contentType, prefix}) ->
  id = resources.length + (item.href for item in resources).join ':'

  if not resource = idResourceCache[id]
    # Create a new resource and load async
    resource = idResourceCache[id] = {
      id
      contentType
      modified: new Date()
      content: {href: resource.href, complete: false} for resource in resources
      deferred: []
    }

    # Generate a unique key that should surivive restarts and multiple instances
    hash = crypto.createHash 'sha1'
    hash.update id
    path = (prefix ? '') + hash.digest 'hex'
    pathResourceCache[path] = resource

    root = if root then resourceRequest.relativeRoot(req, root) else resourceRequest.relativeRoot(req)
    for content in resource.content
      do (content) ->
        chunks = []
        resourceRequest.get(
          content.href,
          root,
          (err, response) ->
            if err
              console.error "Unable to load combined resource #{content.href}", root, err
              content.data = ''
              content.complete = true
            else
              response.on 'data', (chunk) ->
                chunks.push chunk
              response.on 'end', ->
                content.data = chunks.join('') + (separator ? '')
                content.complete = true
                checkComplete resource
        )

  # Let the world know
  externalResourceCache.store {
    path
    prefix
    separator
    contentType
    root: root.url
    hrefs: (item.href for item in resources)
  }

  contentPath + path

exports.middleware = (options) ->
  contentPath = options?.contentPath ? contentPath

  # Init the redis connection unless expicitly disabled by the caller
  if not options?.disableRedis
    client = redis.createClient options?.redisPort, options?.redisHost
    client.on 'error', (err) ->
      # Simply log any redis failures. If we do not have access to redis we might be able
      # to continue operating normally if the proper resource definitions have been cached.
      console.error 'Error communicating with the redis instance', err

  (req, res, next) ->
    # Anything that starts with the content path is a potential resource
    if req.url.indexOf(contentPath) == 0
      sendContent = (resource) ->
        # WARN: This will need to be redone using md5 or similar if there are multiple servers
        etag = resource.modified.getTime()
        modified = resource.modified
        responseCache.setCacheHeaders res, etag, modified

        if responseCache.shouldSendResponse req, etag, modified
          res.setHeader 'Content-Type', resource.contentType
          res.setHeader 'Content-Length', resource.content.length
          res.setHeader header, value for header, value of resource.headers
          res.end resource.content
        else
          responseCache.sendNotModified res

      checkDeferred = (resource) ->
        if resource.deferred
          resource.deferred.push (content) ->
            resource.content = content
            sendContent resource
          checkComplete resource
        else
          sendContent resource

      path = req.url.substring contentPath.length
      resource = pathResourceCache[path]
      if not resource
        externalResourceCache.load path, (resource) ->
          if not resource
            return next()

          # Init the new object
          resource.req = req
          exports.combine resource

          # Start wait for build to complete then serve it up
          checkDeferred pathResourceCache[path]
      else
        checkDeferred resource
    else
      next()
