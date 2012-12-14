# Globals
fs = require "fs"
path = require "path"
http = require "http"
https = require "https"
gzippo = require "gzippo"
express = require "express"

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
