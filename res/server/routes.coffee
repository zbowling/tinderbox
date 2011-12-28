


exports.routes = (app, instance) ->
  main = require('./controllers/main').main(app,instance)
  
  app.get '/', (res,req) -> main.home(res,req)
  app.get '/main', (res,req) -> main.home(res,req)
  app.get '/auth', (res,req) -> main.auth(res,req)
  app.get '/account', (res,req) -> main.account(res,req)
  app.get '/post_account', (res,req) -> main.post_account(res,req)
  
  room = require('./controllers/room').room(app,instance)
  
  app.get '/rooms', (res,req) -> room.room_list(res,req)
  app.get '/room/:id', (res,req) -> room.room(res,req)
  
