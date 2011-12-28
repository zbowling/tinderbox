

Campfire = require('campfire').Campfire

campfire = (instance) -> 
  options = 
    account: instance.account
    token: instance.access_token
    ssl: yes
    oauth: yes

  new Campfire(options)


exports.setup = (app, instance)->
  ioroom = instance.io.of("/roomsocket").on 'connection', (socket) ->
    console.log "user connected"
    camp = null
    room = null
    socket.on "init", (roomid) ->
      console.log "socket init"
      campfire(instance).join roomid, (error, roomobj) ->
        room = roomobj
        room.show (callback) ->
          socket.emit "ready", callback
          room.listen (message) ->
            socket.emit "message", message
    
    socket.on "speak", (text) ->  
      room.speak text, (callback) ->
        socket.emit "sent-speak", callback

exports.room = (app,instance) ->  
    room: (req, res) ->
      res.render "room"
    room_list: (req, res) ->
      campfire(instance).rooms (error, rooms) ->
        console.log(error)
        res.render "rooms", 
          rooms: rooms
          error: error

  