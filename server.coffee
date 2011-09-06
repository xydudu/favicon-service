## 找到一个网站的favicon并返回过来
# 
# 根据所得url 取得 favurl
#   根目录下的
#   查找页面 link(rel="icon") 的
#   默认的

sys     = require 'sys'
fav     = require './module/favicon'
express = require 'express'
request = require 'request'

app     = express.createServer()
icon    = false
sended  = false

app.use express.bodyParser()
app.use express.static(__dirname + '/public')
app.set 'views', __dirname + '/view'
app.set 'view engine', 'jade'
app.set 'view options', layout: false

app.get /^\/fav\/(.+)/, ( req, res ) ->

    favurl = req.params[0]
    f = new fav favurl, req, res, "#{__dirname}/public/favicon.png", "#{__dirname}/public/cache"

    
app.get "/", ( req, res ) ->

    res.render 'index', domain: 'node.local:8081'
        

console.log 'ok, port 8081'
app.listen '8081'

saveFile = ( $key, $data )->

    fs.writeFile "#{__dirname}/public/cache/#{$key}", $data, 'binary', ( $err )->
        if $err
            console.log 'save have problem'
        else
            console.log 'It\'s saved!'

getFromAPI = ( $url, $fun )->
    request.get uri: "http://www.google.com/s2/favicons?domain=#{$url}", encoding: 'binary', timeout: 10000, ( $err, $res, $data )->
        if not $err then return $fun $data
        fs.readFile "#{__dirname}/public/favicon.png", "binary", ( $err, _data )->
            if not $err
                $fun _data
