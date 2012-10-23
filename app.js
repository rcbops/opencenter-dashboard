// Globals
var express = require('express'),
routes = require('./routes'),
http = require('http'),
path = require('path');

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
//    app.use(express.cookieParser('your secret here'));
//    app.use(express.session());
    app.use(app.router);
    app.use(express.static(path.join(__dirname, 'public')));
});

// Profiles
app.configure('production', function() {
    app.use(express.errorHandler())
})
app.configure('development', function(){
    app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
})

// Routes
app.get('/', routes.index);
app.get('/api/:path', function(req, res) {
    var options = {
        'port': '8080',
        'path': req.params.path + '/'
    };

    var hreq = http.request(options, function(hres) {
//        res.setEncoding('utf8');
        res.statusCode = hres.statusCode;
        res.setHeader('Content-Type', 'application/json');

        hres.on('data', function(chunk) {
            res.send(chunk);
        });
    }).on('error', function(e) {
        console.log('Got error: ' + e.message);
        res.statusCode = 500;
        res.end();
    });

    hreq.end();
});

// Create
http.createServer(app).listen(app.get('port'), function(){
    console.log("Express server listening on port " + app.get('port') + " in " + app.settings.env + " mode");
});
