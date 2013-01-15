# Globals
fs = require "fs"
path = require "path"
http = require "http"
https = require "https"
gzippo = require "gzippo"
express = require "express"
config = require "./config"

# App
app = express()

# Config
app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "sport", process.env.SPORT or 3443
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.favicon()
  app.use express.logger "dev"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router

# Profiles
app.configure "production", ->
  # Use gzip/1 day cache
  app.use gzippo.staticGzip path.join __dirname, "public"
  app.use express.errorHandler()

app.configure "development", ->
  # no compression/no cache
  app.use express.static path.join __dirname, "public"
  app.use express.errorHandler
    dumpExceptions: true
    showStack: true

# Routes
app.get "/", (req, res) ->
  res.render "index",
    title: "nTrapy"

# TODO: Rewrite sessiony bits for MySQL

# API
app.post "/api/login", (req, res) ->
  #nano = require("nano") "http://localhost:5984"
  if not req.body.user? or not req.body.pass?
    res.send 401, "Missing user and/or pass!"
  else
    #nano.request
    #  method: "POST"
    #  db: "_session"
    #  form:
    #    name: req.body.user
    #    password: req.body.pass
    #  content_type: "application/x-www-form-urlencoded; charset=utf-8"
    #, (err, body, headers) ->
    #  if err
    #    res.send err.reason
    #  else
    #    if headers?["set-cookie"]
    #      res.cookie headers["set-cookie"]
    #    res.send "Logged in!"

app.post "/api/logout", (req, res) ->
  res.clearCookie "AuthSession"
  res.send "Logged out!"

app.post "/api/:db/:doc", (req, res) ->
  auth = req.cookies["AuthSession"]
  unless auth?
    res.send 401, "Error: Login first"
  else
    #nano = require("nano")
    #  url: "http://localhost:5984"
    #  cookie: "AuthSession=" + auth
    # 
    #db = nano.use req.params.db
    #db.get req.params.doc, (err, body) ->
    #  if err?
    #    res.send 400, "Error: /" + req.params.db + "/" + req.params.doc + " returned: " + err.reason
    #  else
    #    res.cookie headers["set-cookie"] if headers?["set-cookie"]
    #    res.send body
    res.send "Stub"

app.get "/api/:db/:doc", (req, res) ->
  #nano = require("nano") "http://localhost:5984"
  #db = nano.use req.params.db
  #db.get req.params.doc, (err, body) ->
  #  if err?
  #    res.send 400, "Error: /" + req.params.db + "/" + req.params.doc + " returned: " + err.reason
  #  else
  #    res.cookie headers["set-cookie"] if headers?["set-cookie"]
  #    res.send body


# HTTP server
http.createServer(app).listen app.get("port"), ->
  console.log "Express server listening on port " + app.get("port") + " in " + app.settings.env + " mode"

# TODO: See about stuffing this logic into callbacks on readFile
try
  # TLS setup
  tlsOptions =
    key: fs.readFileSync "key.pem"
    cert: fs.readFileSync "cert.pem"
  
  # HTTPS server
  https.createServer(tlsOptions, app).listen app.get("sport"), ->
    console.log "Express https server listening on port " + app.get("sport") + " in " + app.settings.env + " mode"

catch e
  console.log e
  console.log "Error setting up HTTPS; skipping."
