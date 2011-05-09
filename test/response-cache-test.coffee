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
  assert.eql dateStr, responseCache.getResponseCacheInfo({ eTAG: dateStr })?.etag, 'ETag object'
  assert.eql dateStr, responseCache.getResponseCacheInfo(responseMock { etag: dateStr })?.etag, 'Etag mock'

exports['getResponseCacheInfo expires'] = ->
  assert.eql date, responseCache.getResponseCacheInfo({ EXPIRES: dateStr })?.expires, 'Expires object'
  assert.eql date, responseCache.getResponseCacheInfo(responseMock { expires: dateStr })?.expires, 'Expires mock'

exports['getResponseCacheInfo max-age'] = ->
  assert.eql date2, responseCache.getResponseCacheInfo({ 'cache-CONTROL': 'max-age=60', EXPIRES: dateStr }, date)?.expires, 'max-age object'
  assert.eql date2, responseCache.getResponseCacheInfo(responseMock({ 'cache-control': 'max-age=60' }), date)?.expires, 'max-age mock'
  assert.eql date2, responseCache.getResponseCacheInfo(responseMock({ 'cache-control': 'max-age=60', 'date': dateStr }))?.expires, 'max-age date'

exports['getResponseCacheInfo no-cache'] = ->
  assert.eql undefined, responseCache.getResponseCacheInfo({ PRAGMA: 'NO-CACHE', expires: 'Thu, 01 Dec 1994 16:00:00 GMT' }), 'pragma no-cache object'
  assert.eql undefined, responseCache.getResponseCacheInfo(responseMock { pragma: 'NO-CACHE', expires: 'Thu, 01 Dec 1994 16:00:00 GMT' }), 'pragma no-cache mock'

  assert.eql undefined, responseCache.getResponseCacheInfo({ 'CACHE-control': ' NO-cache, test', expires: 'Thu, 01 Dec 1994 16:00:00 GMT' }), 'cache-control no-cache object'
  assert.eql undefined, responseCache.getResponseCacheInfo(responseMock { 'cache-control': ' NO-cache, test', expires: 'Thu, 01 Dec 1994 16:00:00 GMT' }), 'cache-control no-cache mock'

  assert.eql undefined, responseCache.getResponseCacheInfo({ 'cache-CONTROL': 'test' }), 'no-headers no-cache object'
  assert.eql undefined, responseCache.getResponseCacheInfo(responseMock { 'cache-control': 'test' }), 'no-headers no-cache mock'

