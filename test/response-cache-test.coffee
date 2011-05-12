assert = require 'assert'
responseCache = require '../lib/response-cache.coffee'

dateStr = 'Thu, 01 Dec 1994 16:00:00 GMT'
dateStr2 = 'Thu, 01 Dec 1994 16:01:00 GMT'
date = new Date dateStr
date2 = new Date dateStr2

#
# getRequestCacheInfo
#
exports['getRequestCacheInfo if-match'] = ->
  expected = { match: ['"' + dateStr + '"'], noMatch: undefined, modifiedSince: undefined, unmodifiedSince: undefined }
  assert.eql expected, responseCache.getRequestCacheInfo({ 'IF-match': '"' + dateStr + '"' }) , 'if-match single'

  expected = { match: ['W/"' + dateStr + '"'], noMatch: undefined, modifiedSince: undefined, unmodifiedSince: undefined }
  assert.eql expected, responseCache.getRequestCacheInfo({ 'IF-match': 'W/"' + dateStr + '"' }) , 'if-match weak'

  expected = { match: ['"test , test"', 'W/"foo"'], noMatch: undefined, modifiedSince: undefined, unmodifiedSince: undefined }
  assert.eql expected, responseCache.getRequestCacheInfo({ 'IF-match': '"test , test", W/"foo"' }) , 'if-match multiple'

  expected = { match: ['*'], noMatch: undefined, modifiedSince: undefined, unmodifiedSince: undefined }
  assert.eql expected, responseCache.getRequestCacheInfo({ 'IF-match': '*' }), 'if-match star'

  assert.eql undefined, responseCache.getRequestCacheInfo({ 'IF-match': dateStr }), 'if-match invalid'

exports['getRequestCacheInfo if-none-match'] = ->
  expected = { noMatch: ['"' + dateStr + '"'], match: undefined, modifiedSince: undefined, unmodifiedSince: undefined }
  assert.eql expected, responseCache.getRequestCacheInfo({ 'IF-nonE-match': '"' + dateStr + '"' }) , 'if-none-match single'

  expected = { noMatch: ['W/"' + dateStr + '"'], match: undefined, modifiedSince: undefined, unmodifiedSince: undefined }
  assert.eql expected, responseCache.getRequestCacheInfo({ 'IF-nonE-match': 'W/"' + dateStr + '"' }) , 'if-none-match weak'

  expected = { noMatch: ['"test , test"', 'W/"foo"'], match: undefined, modifiedSince: undefined, unmodifiedSince: undefined }
  assert.eql expected, responseCache.getRequestCacheInfo({ 'IF-nonE-match': '"test , test", W/"foo"' }) , 'if-none-match multiple'

  expected = { noMatch: ['*'], match: undefined, modifiedSince: undefined, unmodifiedSince: undefined }
  assert.eql expected, responseCache.getRequestCacheInfo({ 'IF-nonE-match': '*' }), 'if-none-match star'

  assert.eql expected, responseCache.getRequestCacheInfo({ 'IF-nonE-match': dateStr }), 'if-none-match invalid'

#
# getResponseCacheInfo
#
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

  expected = { etag: undefined, expires: new Date(0), lastModified: undefined }
  assert.eql expected, responseCache.getResponseCacheInfo({ EXPIRES: 'aaaa' }), 'Expires invalid'

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

