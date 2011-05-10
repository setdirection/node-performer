assert = require 'assert'
responseCache = require '../lib/response-cache.coffee'

dateStr = 'Thu, 01 Dec 1994 16:00:00 GMT'
dateStr2 = 'Thu, 01 Dec 1994 16:01:00 GMT'
date = new Date dateStr
date2 = new Date dateStr2

responseMock = (headers) ->
  getHeader: (name) ->
    headers[name.toLowerCase()]

exports['getResponseCacheInfo etag'] = ->
  expected = { etag: dateStr, expires: undefined, lastModified: undefined }
  assert.eql expected, responseCache.getResponseCacheInfo({ eTAG: dateStr }), 'Etag object'
  assert.eql expected, responseCache.getResponseCacheInfo(responseMock { etag: dateStr }), 'Etag mock'

exports['getResponseCacheInfo expires'] = ->
  expected = { etag: undefined, expires: date, lastModified: undefined }
  assert.eql expected, responseCache.getResponseCacheInfo({ EXPIRES: dateStr }), 'Expires object'
  assert.eql expected, responseCache.getResponseCacheInfo(responseMock { expires: dateStr }), 'Expires mock'

exports['getResponseCacheInfo last-modified'] = ->
  expected = { etag: undefined, expires: undefined, lastModified: date }
  assert.eql expected, responseCache.getResponseCacheInfo({ 'LAST-MODIFIED': dateStr }), 'Last Modified object'
  assert.eql expected, responseCache.getResponseCacheInfo(responseMock { 'last-modified': dateStr }), 'Last Modified mock'

exports['getResponseCacheInfo max-age'] = ->
  expected = { etag: undefined, expires: date2, lastModified: undefined }
  assert.eql expected, responseCache.getResponseCacheInfo({ 'cache-CONTROL': 'max-age=60', EXPIRES: dateStr }, date), 'max-age object'
  assert.eql expected, responseCache.getResponseCacheInfo(responseMock({ 'cache-control': 'max-age=60' }), date), 'max-age mock'
  assert.eql expected, responseCache.getResponseCacheInfo(responseMock({ 'cache-control': 'max-age=60', 'date': dateStr })), 'max-age date'

exports['getResponseCacheInfo no-cache'] = ->
  assert.eql undefined, responseCache.getResponseCacheInfo({ PRAGMA: 'NO-CACHE', expires: 'Thu, 01 Dec 1994 16:00:00 GMT' }), 'pragma no-cache object'
  assert.eql undefined, responseCache.getResponseCacheInfo(responseMock { pragma: 'NO-CACHE', expires: 'Thu, 01 Dec 1994 16:00:00 GMT' }), 'pragma no-cache mock'

  assert.eql undefined, responseCache.getResponseCacheInfo({ 'CACHE-control': ' NO-cache, test', expires: 'Thu, 01 Dec 1994 16:00:00 GMT' }), 'cache-control no-cache object'
  assert.eql undefined, responseCache.getResponseCacheInfo(responseMock { 'cache-control': ' NO-cache, test', expires: 'Thu, 01 Dec 1994 16:00:00 GMT' }), 'cache-control no-cache mock'

  assert.eql undefined, responseCache.getResponseCacheInfo({ 'cache-CONTROL': 'test' }), 'no-headers no-cache object'
  assert.eql undefined, responseCache.getResponseCacheInfo(responseMock { 'cache-control': 'test' }), 'no-headers no-cache mock'

