# Globals
fs = require "fs"
path = require "path"
http = require "http"
https = require "https"
gzippo = require "gzippo"
express = require "express"
request = require "request"
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
  app.use express.favicon()
  app.use express.logger("dev")
  app.use express.bodyParser()
  app.use express.methodOverride()
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

# Because *SOMEBODY* doesn't know how to check for {}
isEmpty = (obj) ->
  !Object.keys(obj).length > 0

# OpenCenter proxy, woo!
app.all "/octr/?*", (req, res) ->
  options =
    url: config.opencenter_url.replace(/\/$/, "") + req.originalUrl.replace(/\/octr/, "")
    json: if isEmpty req.body then "" else req.body
    # TODO: Figure out why this is broken: headers: req.headers ? {}
    method: req.method
    followAllRedirects: true
    timeout: unless req.param("poll")? then config.timeout.short else (config.timeout.long + 1000)

  req.pipe(request options, (err, resp, body) ->
    if err?
      res.status 502 # Bad gateway
      res.send resp if resp? # Send something if we got it
      res.send err # Send error
  ).pipe res

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
