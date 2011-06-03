resourceRequest = require './resource-request.coffee'
virtual = require './virtual-resource.coffee'
crypto = require 'crypto'

idResourceCache = {}
pathResourceCache = {}

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
exports.combine = ({resources, req, separator, contentType, prefix}) ->
  id = resources.length + (resource.href for resource in resources).join ':'

  if not resource = idResourceCache[id]
    # Create a new resource and load async
    resource = idResourceCache[id] = {
      id
      content: {href: resource.href, complete: false} for resource in resources
      deferred: []
    }

    # Generate a unique key that should surivive restarts and multiple instances
    hash = crypto.createHash 'sha1'
    hash.update id
    path = (prefix ? '') + hash.digest 'hex'
    pathResourceCache[path] = resource

    for content in resource.content
      do (content) ->
        chunks = []
        resourceRequest.get(
          content.href,
          req,
          (err, res) ->
            if err
              console.log "Unable to load combined resource #{content.href}", err
              content.data = ''
              content.complete = true
            else
              res.on 'data', (chunk) ->
                chunks.push chunk
              res.on 'end', ->
                content.data = chunks.join('') + (separator ? '')
                content.complete = true
                checkComplete resource
        )

    resource.href = virtual.create
      id: id
      content: (callback) ->
        if resource.deferred
          resource.deferred.push callback
          checkComplete()
        else
          callback resource.content
      contentType: contentType
      prefix: prefix

  # TODO Figure out a better way to map to the virtual middleware
  '/virtual/' + resource.href
