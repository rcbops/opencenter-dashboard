# Globals
fs = require "fs"
url = require "url"
path = require "path"
http = require "http"
https = require "https"
gzippo = require "gzippo"
express = require "express"
httpProxy = require "http-proxy"
config = require "./config.json"

# Watch and copy CSS until we're using a watchful CSS compiler
fs.watch "source/css/custom.css", {}, (event) ->
  if event is "change"
    fs.createReadStream("source/css/custom.css").pipe fs.createWriteStream("public/css/custom.css")

# App
app = express()

# Config
app.configure ->
  app.set "port", process.env.PORT or 3000
  app.set "sport", process.env.SPORT or 3443
  app.use express.favicon(path.join __dirname, "source/favicon.ico")
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use require("connect-restreamer")()
  app.use app.router

# Profiles
app.configure "production", ->
  # Use gzip/1 day cache
  app.use gzippo.staticGzip(path.join __dirname, "public")
  app.use express.errorHandler()

app.configure "development", ->
  # no compression/no cache
  app.use express.static(path.join __dirname, "public")
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true)

# Get all allowed keys
app.get "/api/config", (req, res) ->
  ret = {}
  for k,v of config when k in config.allowedKeys
    ret[k] = v
  res.send ret

# Get key by name
app.get "/api/config/:key", (req, res) ->
  key = req.param "key"
  if key in config.allowedKeys
    res.send config?[key] ? {}
  else
    res.send "Invalid key"

# OpenCenter proxy, woo!
app.all "/octr/?*", (req, res) ->
  req.url = req.originalUrl.replace(/\/octr/, "")
  parsed = url.parse config.opencenter_url
  proxy = new httpProxy.RoutingProxy()
  proxy.proxyRequest req, res,
    host: parsed.hostname
    port: parsed.port

# HTTP server
http.createServer(app).listen app.get("port"), "::", ->
  console.log "HTTP Server listening on port #{app.get('port')} in #{app.settings.env} mode"

# TODO: See about stuffing this logic into callbacks on readFile
try
  # TLS setup
  tlsOptions =
    key: fs.readFileSync "key.pem"
    cert: fs.readFileSync "cert.pem"

  # HTTPS server
  https.createServer(tlsOptions, app).listen app.get("sport"), "::", ->
    console.log "HTTPS server listening on port #{app.get('sport')} in #{app.settings.env} mode"

catch e
  console.log e
  console.log "Error setting up HTTPS; skipping."
