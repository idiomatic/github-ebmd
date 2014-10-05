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
user_agent = 'github-embd'
port = 8080
scope = 'repo,read:org'
secret = 'hackath0n'
per_page = 100
max_pages = 3

urlTweak = (base_url, how) ->
    u = url.parse base_url, true
    for k, v of how
        if k is 'query'
            for qk, qv of v
                u.query[qk] = qv
        else
            u[k] = v
    delete u.host
    delete u.path
    return url.format u

app = express()
app.engine 'jade', jade.__express
app.set 'view engine', 'jade'
app.use session {secret, resave:false, saveUninitialized:false}

# oauth2
app.use (req, res, next) ->
    unless req.session?.state
        await crypto.randomBytes 48, defer err, state
        req.session.state = state.toString 'hex'
    req.redirect_uri = urlTweak "http://#{req.hostname}:#{port}/oauth2callback"
    next()


class GitHub
    constructor: (@access_token) ->
    authorize_uri: (req) ->
        {redirect_uri, session:{state}} = req
        urlTweak 'https://github.com/login/oauth/authorize',
            query: {client_id, redirect_uri, scope, state}
    get: (uri, query, cb) ->
        # XXX automatic pager?
        return cb new Error "not authorized" unless @access_token
        options =
            url: urlTweak uri, {query}
            headers:
                Accept: 'application/vnd.github.v3+json'
                Authorization: "token #{@access_token}"
                'User-Agent': user_agent
        await request.get options, defer err, response, body
        return cb err if err
        return cb null, JSON.parse body
    getAll: (uri, query, cb) ->
        all_items = []
        query.per_page = per_page
        for page in [1..max_pages]
            query.page = page
            await @get uri, query, defer err, items
            return cb err if err
            break unless items?.length
            all_items.push.apply all_items, items
            # assuming this is not one of those that disregards per_page
            break if items.length < per_page
        return cb null, all_items
    orgs: (args..., cb) ->
        {username} = query = args[0] or {}
        uri = switch true
            when username?
                delete opts.username
                "https://api.github.com/users/#{username}/orgs"
            else
                'https://api.github.com/user/orgs'
        @get uri, query, cb
    repos: (args..., cb) ->
        {org} = query = args[0] or {}
        uri = switch true
            when org?
                delete query.org
                "https://api.github.com/orgs/#{org}/repos"
            else
                'https://api.github.com/user/repos'
        @get uri, query, cb
    milestones: (args..., cb) ->
        {repo} = query = args[0] or {}
        uri = "https://api.github.com/repos/#{repo}/milestones"
        @get uri, query, cb
    issues: (args..., cb) ->
        {repo, org} = query = args[0] or {}
        uri = switch true
            when repo?
                delete query.repo
                "https://api.github.com/repos/#{repo}/issues"
            when org?
                delete query.org
                "https://api.github.com/orgs/#{org}/issues"
            else
                "https://api.github.com/issues"
        @getAll uri, query, cb
    comments: (args..., cb) ->
        {repo, number} = query = args[0] or {}
        uri = "https://api.github.com/repos/#{repo}/issues/#{number}/comments"
        @get uri, query, cb
        

app.get '/', (req, res, next) ->
    {token} = req.session
    github = new GitHub token?.access_token
    if token
        err = {}
        await
            github.repos defer err.repos, repos
            github.orgs defer err.orgs, orgs
        await
            for org in orgs
                {login} = org
                github.repos {org:login}, defer err[login], org.repos
        await
            for org in orgs
                {login} = org
                for repo in org.repos
                    repo.milestones = {}
                    {full_name, milestones} = repo
                    github.milestones {repo:full_name}, defer err[full_name], repo.milestones
        await
            for org in orgs
                for repo in org.repos
                    {full_name} = repo
                    repo.milestones.push {number:'none', title:'none'}
                    for milestone in repo.milestones
                        {number, title} = milestone
                        github.issues {repo:full_name, milestone:number, state:'all'}, defer err[title], milestone.issues
        # XXX comments
    authorize_uri = github.authorize_uri req
    res.render 'index', {inspect:util.inspect, authorize_uri, token, repos, orgs}

app.get '/oauth2callback', (req, res, next) ->
    {code, state} = req.query
    if state isnt req.session.state
        return next new Error 'cross-site scripting attack foiled'
    {redirect_uri} = req
    token_uri = urlTweak 'https://github.com/login/oauth/access_token',
        {query: {client_id, client_secret, code, redirect_uri}}
    await request.post token_uri, defer err, response, body
    return next err if err
    req.session.token = querystring.parse body
    res.redirect '/'

app.listen port
