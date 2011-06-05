assert = require 'assert'
net = require 'net'
resourceRequest = require '../lib/resource-request.coffee'

TEST_PORT = 60657

exports['Global URL'] = ->
  req = {url: "/foo/bar"}
  assert.eql {host: 'www.google.com', port: 80, path: '/'}, resourceRequest.options('http://www.google.com', req), 'Global url root'
  assert.eql {host: 'www.google.com', port: 80, path: '/'}, resourceRequest.options('http://www.google.com/', req), 'Global url root /'
  assert.eql {host: 'www.google.com', port: 80, path: '/?1=1'}, resourceRequest.options('http://www.google.com?1=1', req), 'Global url root param'

  assert.eql {host: 'www.google.com', port: 80, path: '/test?1=1'}, resourceRequest.options('http://www.google.com/test?1=1', req), 'Global url path'

exports['Local URL'] = ->
  req =
    socket:
      address: ->
        address: '127.0.0.1'
        port: 123
    url: "/"

  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('', req)
  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('/', req), 'Local url root /'
  assert.eql {host: '127.0.0.1', port: 123, path: '/?1=1'}, resourceRequest.options('?1=1', req), 'Local url root param'

  assert.eql {host: '127.0.0.1', port: 123, path: '/test?1=1'}, resourceRequest.options('test?1=1', req), 'Local url path'

exports['Local URL Cached'] = ->
  req =
    address: '127.0.0.1'
    port: 123
    url: "/"

  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('', req), 'Local url root'
  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('/', req), 'Local url root /'
  assert.eql {host: '127.0.0.1', port: 123, path: '/?1=1'}, resourceRequest.options('?1=1', req), 'Local url root param'

  assert.eql {host: '127.0.0.1', port: 123, path: '/test?1=1'}, resourceRequest.options('test?1=1', req), 'Local url path'

exports['Local URL Folder'] = ->
  req =
    socket:
      address: ->
        address: '127.0.0.1'
        port: 123
    url: "/foo/bar"

  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/bar'}, resourceRequest.options('', req), 'Local url folder root'
  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('/', req), 'Local url folder root /'
  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/bar?1=1'}, resourceRequest.options('?1=1', req), 'Local url folder root param'

  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/test?1=1'}, resourceRequest.options('test?1=1', req), 'Local url folder path'

exports['Local URL Folder Cached'] = ->
  req =
    address: '127.0.0.1'
    port: 123
    url: "/foo/bar"

  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/bar'}, resourceRequest.options('', req), 'Local url folder root'
  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('/', req), 'Local url folder root /'
  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/bar?1=1'}, resourceRequest.options('?1=1', req), 'Local url folder root param'

  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/test?1=1'}, resourceRequest.options('test?1=1', req), 'Local url folder path'

exports['Local URL Folder relativeRoot Cached'] = ->
  req =
    resourceRequest.relativeRoot
      socket:
        address: ->
          address: '127.0.0.1'
          port: 123
      url: "/foo/bar"

  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/bar'}, resourceRequest.options('', req)
  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('/', req), 'Local url folder root /'
  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/bar?1=1'}, resourceRequest.options('?1=1', req), 'Local url folder root param'

  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/test?1=1'}, resourceRequest.options('test?1=1', req), 'Local url folder path'

exports['Local URL Folder relativeRoot change url Cached'] = ->
  req =
    resourceRequest.relativeRoot
      socket:
        address: ->
          address: '127.0.0.1'
          port: 123
      url: "/foo/bar",
      "/foo/baz/bar"

  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/baz/bar'}, resourceRequest.options('', req)
  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('/', req), 'Local url folder root /'
  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/baz/bar?1=1'}, resourceRequest.options('?1=1', req), 'Local url folder root param'

  assert.eql {host: '127.0.0.1', port: 123, path: '/foo/baz/test?1=1'}, resourceRequest.options('test?1=1', req), 'Local url folder path'


exports['Root relativeRoot'] = ->
  req =
    resourceRequest.relativeRoot
      socket:
        address: ->
          address: '127.0.0.1'
          port: 123
      url: "/"

  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('', req)
  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('/', req), 'Local url folder root /'
  assert.eql {host: '127.0.0.1', port: 123, path: '/?1=1'}, resourceRequest.options('?1=1', req), 'Local url folder root param'

  assert.eql {host: '127.0.0.1', port: 123, path: '/test?1=1'}, resourceRequest.options('test?1=1', req), 'Local url folder path'

  req =
    resourceRequest.relativeRoot
      socket:
        address: ->
          address: '127.0.0.1'
          port: 123
      url: ""

  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('', req)
  assert.eql {host: '127.0.0.1', port: 123, path: '/'}, resourceRequest.options('/', req), 'Local url folder root /'
  assert.eql {host: '127.0.0.1', port: 123, path: '/?1=1'}, resourceRequest.options('?1=1', req), 'Local url folder root param'

  assert.eql {host: '127.0.0.1', port: 123, path: '/test?1=1'}, resourceRequest.options('test?1=1', req), 'Local url folder path'

exports['Local URL Socket'] = ->
  try
    server = net.createServer ->
    server.listen TEST_PORT, 'localhost'
    req =
      socket: server
      url: "/foo/bar"

    assert.eql {host: '127.0.0.1', port: TEST_PORT, path: '/foo/bar'}, resourceRequest.options('', req), 'Local url socket root'
    assert.eql {host: '127.0.0.1', port: TEST_PORT, path: '/'}, resourceRequest.options('/', req), 'Local url socket root /'
    # TODO : Is this valid?
    assert.eql {host: '127.0.0.1', port: TEST_PORT, path: '/foo/bar?1=1'}, resourceRequest.options('?1=1', req), 'Local url socket root param'

    assert.eql {host: '127.0.0.1', port: TEST_PORT, path: '/foo/test?1=1'}, resourceRequest.options('test?1=1', req), 'Local url socket path'

  finally
    server.close()
