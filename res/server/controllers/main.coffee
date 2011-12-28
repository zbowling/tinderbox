

rest = require 'restler'
client_id = "5d501034a4c4339ef2dd0e829e1692e119f9e407"
client_secret = "e3d39fe7c01d477d3d8d889e97f73e1d31db4936"
auth_endpoint = "https://launchpad.37signals.com/authorization"

exports.main = (app,instance) -> 
  home: (req, res) ->
    redirect_api = encodeURIComponent("http://tinderbox.local/auth")
    api_endpoint = "#{auth_endpoint}/new?type=web_server&client_id=#{ client_id }&redirect_uri=#{ redirect_api }"
    res.redirect api_endpoint
  
  
  auth: (req, res) ->
    auth_code = req.param "code"
    data = 
      type: "web_server"
      client_id: client_id
      client_secret: client_secret
      code: auth_code
      redirect_uri: "http://tinderbox.local/auth"
      format: "json"
      
    token_call = rest.post "#{auth_endpoint}/token", {data:data}
    token_call.on "complete", (data, response) -> 
      instance.access_token = data.access_token
      res.redirect "http://tinderbox.local/account"
      
  
  post_account: (req, res) ->
    account_name = req.param("account")
    
    #TODO: validate this input
    
    instance.account = account_name.replace(/^\s*/, "").replace(/\s*$/, "")
    res.redirect "http://tinderbox.local/rooms/"
    
  account: (req, res) ->
    res.render "account", 
      account: instance.account ? ""
