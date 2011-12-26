//we listen on this socket
var socketPath = process.argv[2];


var fs = require('fs');

var express = require('express');

var app = express.createServer();
app.use(express.logger());
app.use(express.bodyParser());

app.get('/', function(req, res){
    res.send('I\'m awesome!');
});


app.get('/main', function(req, res){
    res.send('Something magic goes here.');
});

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

