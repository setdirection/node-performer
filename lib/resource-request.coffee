http = require 'http'
url = require 'url'

# Determines the endpoint that the current server is listening on
getLocalConn = (req) ->
  addr = if req.socket? then req.socket.address() else req

  host: addr.address
  port: addr.port

exports.relativeRoot = (req, path) ->
  options = exports.options '', req, path

  address: options.host
  port: options.port
  url: options.path

exports.options = (href, req, path) ->
  options = url.parse url.resolve 'http://localhost'+(path ? req.url), href
  local = getLocalConn req if options.hostname == 'localhost'

  host: local?.host ? options.hostname
  port: local?.port ? options.port ? 80
  path: (if options.pathname[0] != '/' then '/' else '') + (options.pathname ? '') + (options.search ? '')

# GETs the contents of the given resource, relative to the current page (Pinging back to the local server if necessary)
exports.get = (href, req, callback) ->
  http.get(
    exports.options href, req
    (res) ->
      callback undefined, res
  ).on 'error', (e) -> callback e
