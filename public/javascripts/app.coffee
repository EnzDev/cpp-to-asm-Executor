render=(data)->
  if data?
    if data.join("\n").match(/^>>.*/)?
      $("#output").append(data.join("\n").replace(/^\"|\"$/g,""))
    else
      $("#output").append(data.join("\n").replace(/\\n/g,"\n").replace(/^\"|\"$/g,""))

#On page load
$ ()->
  r = ''
  $.post "/launch", "", ()->
    r = setInterval ()->
      console.log("sent")
      $.post "/request", "", (res) ->
        render(res)
        return
    , 1000
    return
  #bind submit button
  $("#send").click (e)->
    #start ajax request
    $.post "/request", $("form").serialize(), ( response )->
      render(response)
      $("#stdin").val("")
    false
  return

