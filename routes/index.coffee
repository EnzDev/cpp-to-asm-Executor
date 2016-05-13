cp = require("child_process")


exports.error404 = (req,res)->
	res.status(404)
	res.render("404")

exports.launchpost = (req,res)-> #here, we will start bash
	process[req.session.id] = cp.spawn("/bin/bash")
	res.send()

exports.reqpost = (req,res)->
	if req.body.stdin?
		toWrite = req.body.stdin
	buff = process[req.session.id].stdout.read()
	out = []
	out.push(JSON.stringify(buff.toString())) if buff?
	if toWrite? and toWrite!=""
		try
			process[req.session.id].stdin.write("#{toWrite}\n")
			out.push(">> #{toWrite}\n")
			console.log("write #{toWrite}\n")
		catch nowrite
			out.push(nowrite)
	res.send(out)

