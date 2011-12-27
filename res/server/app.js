require("coffee-script");

//we listen on this socket
var socketPath = process.argv[2];
var fs = require('fs');
var express = require('express');

var app = express.createServer();
app.use(app.router);
app.use(express.logger());
app.use(express.bodyParser());
app.use(express.cookieParser());
app.use(express.session({ secret: "$ecret" }));
app.use(express.static(__dirname + '/static',{ maxAge: 0 }));
app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
app.register('.html', require('ejs'));
app.set('view engine','html');
app.set('view options', {
    open: '{{',
    close: '}}'
});

require('./routes').routes(app);

function startServer() {
    app.listen(socketPath,function () {
        console.log("OK");
    });
}

fs.unlink(socketPath, function (err) {
  //if (err) throw err; don't care
  startServer();
});

process.stdin.resume();
process.stdin.setEncoding('utf8');

process.stdin.on('end', function () {
    process.exit(0);
});


