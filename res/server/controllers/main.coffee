

exports.home = (req, res) ->
  data = {}
  data.page = {}
  data.page.title = "Hello"
  data.content = "HI"
  res.render("main",data)