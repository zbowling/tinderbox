//we listen on this socket
var socketPath = process.argv[2];

var app = require('express').createServer();

app.get('/', function(req, res){
        res.send('hello world');
        });

app.listen(socketPath);

console.log(socketPath);

