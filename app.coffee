cluster = require('cluster')
numCPUs = require('os').cpus().length


#Let's fork the app !
if cluster.isMaster #if im the parrent
  for i in [1..numCPUs]
    cluster.fork()
else #if i'm a child
  express = require('express') # light and complete framework (w'ill use v4)
  routes = require('./routes') # launch the route
  http = require('http') # use http for listening, ...
  path = require('path') # general path string manipulation purposes

  middle = {} # Add all the express middlewares
  middle.bodyParser = require("body-parser")
  middle.cookieParser = require("cookie-parser")
  middle.favicon = require("serve-favicon")
  middle.session = require("express-session")
  middle.methodOverride = require("method-override")

  app = express() # set up express
  sessionStore = new middle.session.MemoryStore()

# app.configure is deprecated
  app.set('port', process.env.PORT || 8008) # setup the listening port
  app.set('views', __dirname + '/views') # setup the views (there is only the 404 page)
  app.set('view engine', 'ejs') # use ejs for the views (useless cuz here ejs is simple html)
  app.use(middle.favicon(path.join(__dirname, "public/favicon.ico"))) # let express handle the favicon for us
  app.use(middle.bodyParser())
  app.use(middle.methodOverride())

  app.use(middle.cookieParser("Secret"))

  session = middle.session( # init the session
    store: sessionStore # use MemoryStore (because we are in dev)
    genid:()->
      require("crypto").randomBytes(16).toString('hex')
    secret:"Jay Chou"
    resave:false
    saveUninitialized:true
    cookie: # the session expire if unused after 600000 ticks (10min)
      maxAge:600000
  )

  app.use(require('stylus').middleware(__dirname + '/public'))
  app.use(express.static(path.join(__dirname, 'public')))

  app.post '/launch',  session, routes.launchpost   # set the route for launch
  app.post '/request', session, routes.reqpost      # same w request
  app.post '/compile', session, routes.indexpost    #compile into asm


  app.use routes.error404

  http.createServer(app).listen app.get('port'), ()->
    console.log("Express server listening on port " + app.get('port'))
    process = {}
    datas = {}
