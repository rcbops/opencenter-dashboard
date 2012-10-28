// Globals
var express = require('express'),
    http = require('http'),
    path = require('path'),
    gzippo = require('gzippo');

// App
var app = express();

// Config
app.configure(function(){
    app.set('port', process.env.PORT || 3000);
    app.set('views', __dirname + '/views');
    app.set('view engine', 'jade');
    app.use(express.favicon());
    app.use(express.logger('dev'));
    app.use(express.bodyParser());
    app.use(express.methodOverride());
    app.use(app.router);
    app.use(gzippo.staticGzip(path.join(__dirname, 'public')));
});

// Profiles
app.configure('production', function() {
    app.use(express.errorHandler())
})
app.configure('development', function(){
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
})

// Routes
app.get('/', function(req, res) {
    res.render('index', { title: 'nTrapy' });
});

// Create
http.createServer(app).listen(app.get('port'), function(){
    console.log("Express server listening on port " + app.get('port') + " in " + app.settings.env + " mode");
});
