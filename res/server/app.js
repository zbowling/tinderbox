require("coffee-script");
eco = require("eco");

//we listen on this socket
var socketPath = process.argv[2];
var serverPath = process.argv[3];

var fs = require('fs');
var express = require('express');

var app = express.createServer();




app.use(express.logger());
app.use(express.bodyParser());
app.use(express.cookieParser());
app.use(express.session({ secret: "$ecret" }));
app.use(express.static(__dirname + '/static',{ maxAge: 0 }));
app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
app.use(app.router);
app.register('.html', eco);
app.set('view engine','html');
app.set('basepath',"http://tinderbox.local/")

var io = require('socket.io').listen(app);
//io.set('transports', ['htmlfile']);

instance = {};
instance.io = io;

require('./controllers/room').setup(app,instance);

require('./routes').routes(app,instance);

function startServer() {
    app.listen(socketPath,function () {
        console.log("OK");
    });
}

fs.unlink(socketPath, function (err) {
  startServer();
});

process.stdin.resume();
process.stdin.setEncoding('utf8');

process.stdin.on('end', function () {
    process.exit(0);
});


