// Globals
var express = require('express'),
    fs = require('fs'),
    http = require('http'),
    https = require('https'),
    path = require('path'),
    gzippo = require('gzippo');

// App
var app = express();

// Config
app.configure(function() {
    app.set('port', process.env.PORT || 3000);
    app.set('sport', process.env.SPORT || 3443);
    app.set('views', __dirname + '/views');
    app.set('view engine', 'jade');
    app.use(express.favicon());
    app.use(express.logger('dev'));
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(app.router);
});

// Profiles
app.configure('production', function() {
    // Use gzip/1 day cache
    app.use(gzippo.staticGzip(path.join(__dirname, 'public')));
    app.use(express.errorHandler());
});
app.configure('development', function() {
    // no compression/no cache
    app.use(express.static(path.join(__dirname, 'public')));
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
});

// Routes
app.get('/', function(req, res) {
    res.render('index', { title: 'nTrapy' });
});

// HTTP server
http.createServer(app).listen(app.get('port'), function() {
    console.log("Express server listening on port " + app.get('port') + " in " + app.settings.env + " mode");
});

// TLS setup
var tlsOptions = {
    key: fs.readFileSync('key.pem'),
    cert: fs.readFileSync('cert.pem')
};

// HTTPS server
https.createServer(tlsOptions, app).listen(app.get('sport'), function() {
    console.log("Express https server listening on port " + app.get('sport') + " in " + app.settings.env + " mode");
});
