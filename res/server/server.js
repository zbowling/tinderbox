var app = require('express').createServer();

console.log("hello")

app.get('/', function(req, res){
        res.send('hello world');
        });

app.listen(3000);

