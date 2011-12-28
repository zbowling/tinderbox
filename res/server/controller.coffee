Campfire = require('campfire').Campfire

#base controller
class BaseController 
  constructor: (@app, @instance) ->
  
  campfire: (session) ->
    options = 
      account: @instance.account
      ssl: yes
      token: @instance.access_token
    
    new Campfire(options)

exports.base = BaseController