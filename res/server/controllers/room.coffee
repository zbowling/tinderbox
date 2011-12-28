

Campfire = require('campfire').Campfire

exports.room = (app,instance) -> 

  room_list: (req, res) ->
    
    options = 
      account: instance.account
      token: instance.access_token
      ssl: yes
      oauth: yes

    console.log(options)
    
    campfire = new Campfire(options)
    
    campfire.rooms (error, rooms) ->
      console.log(error)
      res.render "rooms", 
        rooms: rooms
        error: error
    
    
  room: (req, res) ->
    