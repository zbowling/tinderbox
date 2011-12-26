//we listen on this socket
var socketPath = process.argv[2];


var fs = require('fs');

var express = require('express');

var app = express.createServer();
app.use(express.logger());
app.use(express.bodyParser());

app.get('/', function(req, res){
        res.send('hello world');
        });


fs.unlink(socketPath, function (err) {
  if (err) throw err;
  app.listen(socketPath,function () {
    console.log("OK");
  });
});



process.stdin.resume();
process.stdin.setEncoding('utf8');

process.stdin.on('end', function () {
    process.exit(0);
});


