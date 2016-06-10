cp = require("child_process")
datas = {}

exports.error404 = (req,res)->
	res.status(404)
	res.render("404")

exports.launchpost = (req,res)-> #here, we will start bash
	datas[req.session.id] = []
	if req.session.name?
		process[req.session.id] = cp.spawn "/tmp/#{req.session.name}"
		process[req.session.id].stdout.on 'data', (dt)->
			datas[req.session.id].push(dt.toString())
		res.json({})


exports.reqpost = (req,res)->
	console.log(JSON.stringify(datas))
	cp.exec "pidof #{req.session.name}", (e,to,te)->
		out = if datas[req.session.id] then datas[req.session.id].slice() else []
		datas[req.session.id] = []
		if !(process[req.session.id]._handle?)
			res.json( {killed : true, cons:out} )
		else
			if req.body.stdin?
				toWrite = req.body.stdin
			
			if toWrite? and toWrite!=""
				try
					process[req.session.id].stdin.write("#{toWrite}\n")
					out.push(">> #{toWrite}\n")
					console.log("write #{toWrite}\n")
				catch nowrite
					out.push(nowrite)
			res.json({cons:out})

	#____________here after: asm viewing_________________

fs = require('fs')
util = require('util')

decodeCode=(asm,code)->
	# split input
	asm_lines = asm.split("\n")
	code_lines = code.split("\n")
	labels={}
	label_data={}
	currentlabel=null
	files=[]
	readmode=false
	currentline=0

	for asline in asm_lines
		linedata=/^[ ]+[0-9]+ (.*)/m.exec(asline)
		if linedata?
			# parse file start markers '.file "filename"'
			file=/^[ \t]*\.file[ \t]+([0-9]*)?[ ]?\"([^"]*)"/m.exec(linedata[1])
			if file?
				fid=if file[1] then file[1] else 0

				fname=file[2]
				files[parseInt(fid)]= /(^test|\/test)/.test(fname)
				readmode=files[parseInt(fid)]
				currentline=0
			else
				# scan for labels
				label=/\.([^ :]*):/m.exec(linedata[1])
				if label?
					if labels[label[1]]?
						labels[label[1]]++
					else
						if currentlabel? and currentlabel < 1
							delete label_data[currentlabel]

						labels[label[1]]= 0
						label_data[label[1]]= {0:linedata[1]+"\n"}
						currentlabel=label[1]
				else if currentlabel?
					# parse .loc
					loc= /^[ \t]*.loc ([0-9]+) ([0-9]+)/.exec(linedata[1])
					if loc?
						readmode=files[parseInt(loc[1])]
						currentline=if readmode then parseInt(loc[2]) else 0
					else
						if not label_data[currentlabel][currentline]?
							label_data[currentlabel][currentline]=""
						label_data[currentlabel][currentline]+= linedata[1]+"\n"
						if readmode
							labels[currentlabel]++

	if currentlabel? and currentlabel < 1
		delete label_data[currentlabel]
	{code:code_lines,asm:label_data}


exports.error404 = (req, res)->
  res.status(404)
  res.render('404', { title: 'C/C++ to Assembly' })

exports.indexpost = (req, res)->
	blocks = {}
	optimize=if req.body.optimize? then "-O2" else ""
	lang=if req.body.language=="c" then "c" else "cpp"

	# generate file name
	fileid=Math.floor(Math.random()*1000000001)
	compiler=if req.body.arm then "arm-linux-gnueabi-g++-4.6" else "gcc"
	asm=if req.body.intel_asm then "-masm=intel" else ""

	allowedstandards = [
		'c++11'
		'c++14'
		'c99'
	]

	if allowedstandards.indexOf(req.body.standard) > -1
		standard = req.body.standard
	else
		standard = 'c99'

	#Write input to file
	fs.writeFile "/tmp/test#{fileid}.#{lang}", req.body.ccode, (err)->
		if err
			res.json({error:"Server Error: unable to write to temp directory"})
		else
			# execute GCC
			compilecmd = "c-preload/compiler-wrapper #{compiler} #{asm} " +
										"-std=#{standard} -c #{optimize} -Wa,-ald " +
										"-g /tmp/test#{fileid}.#{lang}"
			cp.exec compilecmd,
				{timeout:10000,maxBuffer: 1024 * 1024*10},
				(error, stdout, stderr)->
					 
					if error?
						# send error message to the client
						res.json({error:error.toString()})
						# fs.unlink("/tmp/test#{fileid}.#{lang}")
						fs.unlink("test#{fileid}.o")
					else
						# parse standard output
						blocks=decodeCode(stdout,req.body.ccode)

						# verify if the code is executable
						execu = false
						for key, value of blocks.code
						  execu = true if (value.search(/(int|void) *main\(.*\)/) == 0)
						blocks.work = false
						if execu
							## DO THE COMPILATION AND ASSIGNEMENT
						#	fs.unlink("/tmp/test#{fileid}.#{lang}")
							comp = "gcc -std=#{standard}" +
							  " #{optimize} -o /tmp/prg#{fileid} /tmp/test#{fileid}.#{lang}"
							cp.exec comp,
								{timeout:100000,maxBuffer: 1024 * 1024*10},
								(error, stdout, stderr)->
									if error?
										console.log("#{error.toString()}")
										delete req.session.name
									else
										req.session.name = "prg#{fileid}"
										blocks.work = true
										console.log("pass : #{fileid}")

									res.json(blocks)
						else
							res.json(blocks)

						# clean up
						fs.unlink("test#{fileid}.o")
