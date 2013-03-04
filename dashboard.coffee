#               OpenCenter™ is Copyright 2013 by Rackspace US, Inc.
# ###############################################################################
#
# OpenCenter is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.  This version
# of OpenCenter includes Rackspace trademarks and logos, and in accordance with
# Section 6 of the License, the provision of commercial support services in
# conjunction with a version of OpenCenter which includes Rackspace trademarks
# and logos is prohibited.  OpenCenter source code and details are available at:
# https://github.com/rcbops/opencenter or upon written request.
#
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0 and a copy, including this notice,
# is available in the LICENSE file accompanying this software.
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# ###############################################################################
 
# Globals
fs = require "fs"
url = require "url"
path = require "path"
http = require "http"
https = require "https"
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
  app.use express.compress()
  app.use express.static(path.join __dirname, "public")
  app.use express.favicon(path.join __dirname, "public/favicon.ico")
  app.use express.logger("dev")
  app.use express.methodOverride()
  app.use app.router

# Profiles
app.configure "production", ->
  app.use express.errorHandler()

app.configure "development", ->
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
