require("coffee-script");
eco = require("eco");

//we listen on this socket
var socketPath = process.argv[2];

process.stdout.setEncoding('utf8');

var fs = require('fs');
var express = require('express');

var io = require('socket.io');
var app = express.createServer();

io = io.listen(app);

io.configure(function () {
  io.set('transports', ['websocket']);
});

io.sockets.on('connection', function (socket) {
  console.log(socket);
  socket.emit('news', { hello: 'world' });
});



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

//Todo, move to utils
String.prototype.trim = function () {
    return this.replace(/^\s*/, "").replace(/\s*$/, "");
}

instance = {}

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


