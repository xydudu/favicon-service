## 找到一个网站的favicon并返回过来
# 
# 根据所得url 取得 favurl
#   根目录下的
#   查找页面 link(rel="icon") 的
#   默认的

fav     = require './module/favicon'
express = require 'express'
app     = express.createServer()
fs      = require 'fs'
cluster = require 'cluster'
numCPUs = require('os').cpus().length

app.use express.bodyParser()
app.use express.static(__dirname + '/public')
app.set 'views', __dirname + '/view'
app.set 'view engine', 'jade'
app.set 'view options', layout: false

app.get /^\/fav\/(.+)/, ( req, res ) ->

    favurl = req.params[0]
    f = new fav favurl, req, res, "#{__dirname}/public/favicon.png", "#{__dirname}/public/cache"

    
app.get "/fav", ( req, res ) ->
    fs.readdir "#{__dirname}/public/cache", ( $err, $files )->
        console.log $files
        #res.render 'index', domain: 'favicon.xydudu.com', files: $files
        res.render 'index', domain: 'common.tazai.com:8081', files: $files
        
if cluster.isMaster

    cluster.fork() for n in [ numCPUs .. 1 ]
    cluster.on 'death', ( worker )->
        cluster.fork()
        console.log "worker #{ worker.pid } died"
        ###
        TODO over 10 times death, must email the exception
        ###

else
    app.listen '8181'

