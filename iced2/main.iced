crypto = require 'crypto'
querystring = require 'querystring'
url = require 'url'
util = require 'util'
express = require 'express'
session = require 'express-session'
jade = require 'jade'
request = require 'request'

client_id = '8595c1cb95b9fc25b02d'
client_secret = 'd31554e4db1694bcb4346f251594eae335a86872'
port = 8080
scope = 'read:org'              # repo,
secret = 'hackath0n'

urlfrob = (base_url, how) ->
    u = url.parse base_url
    for k, v of how
        #if k is 'query'
        #    # XXX parse incumbent query
        #    u.query ?= {}
        #    for qk, qv of v
        #        u.query[qk] = qv
        #else
        u[k] = v
    return url.format u

app = express()
app.engine 'jade', jade.__express
app.set 'view engine', 'jade'
app.use session {secret, resave:false, saveUninitialized:false}
app.use (req, res, next) ->
    req.redirect_uri = urlfrob "http://#{req.hostname}:#{port}/oauth2callback"
    unless req.session.state
        await crypto.randomBytes 48, defer err, state
        req.session.state = state.toString 'hex'
    next()
app.get '/', (req, res) ->
    {redirect_uri} = req
    {access_token, state} = req.session
    authorize_uri = urlfrob 'https://github.com/login/oauth/authorize',
        query: {client_id, redirect_uri, scope, state}
    res.render 'index', {authorize_uri, access_token}
app.get '/oauth2callback', (req, res, next) ->
    {code, state} = req.query
    if state isnt req.session.state
        return next new Error 'cross-site scripting attack foiled'
    {redirect_uri} = req
    token_uri = urlfrob 'https://github.com/login/oauth/access_token',
        query: {client_id, client_secret, code, redirect_uri}
    await request.post token_uri, defer err, response, body
    req.session.access_token = querystring.parse body
    res.redirect '/'
app.listen port
