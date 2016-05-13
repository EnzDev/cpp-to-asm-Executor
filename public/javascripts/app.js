// Generated by CoffeeScript 1.10.0
(function() {
  var render;

  render = function(data) {
    if (data != null) {
      if (data.join("\n").match(/^>>.*/) != null) {
        return $("#output").append(data.join("\n").replace(/^\"|\"$/g, ""));
      } else {
        return $("#output").append(data.join("\n").replace(/\\n/g, "\n").replace(/^\"|\"$/g, ""));
      }
    }
  };

  $(function() {
    var r;
    r = '';
    $.post("/launch", "", function() {
      r = setInterval(function() {
        console.log("sent");
        return $.post("/request", "", function(res) {
          render(res);
        });
      }, 1000);
    });
    $("#send").click(function(e) {
      $.post("/request", $("form").serialize(), function(response) {
        render(response);
        return $("#stdin").val("");
      });
      return false;
    });
  });

}).call(this);
