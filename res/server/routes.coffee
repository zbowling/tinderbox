
main = require("./controllers/main")
room = require("./controllers/room")

exports.routes = (app) ->
  app.get('/', main.home);
  app.get('/main', main.home);