## 找到一个网站的favicon并返回过来
# 
# 根据所得url 取得 favurl
#   根目录下的
#   查找页面 link(rel="icon") 的
#   默认的

sys     = require 'sys'
fs      = require 'fs'
fav     = require './module/favicon'
express = require 'express'
keygrip = require 'keygrip'
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
    etagKey = keygrip( req.params ).sign 'xydudu'

    if req.header('If-None-Match') is etagKey
        console.log '304'
        res.writeHead 304, 'Content-Type': 'image/png'
        res.end()
        return
    

    fs.readFile "#{__dirname}/public/cache/#{etagKey}.png", "binary", ( $err, $data )->
        if $err
            console.log 'no cache file'
            fav favurl, etagKey, ( $json )->
                if $json.err

                   console.log 'all is err'
                   getFromAPI $json.data, ( $data )->
                        sendIcon.call res, $data, etagKey
                        saveFile etagKey, $json.data

                else
                    sendIcon.call res, $json.data, etagKey
                    saveFile etagKey, $json.data
        else
            console.log 'use cache file'
            sendIcon.call res, $data, etagKey

    
app.get "/", ( req, res ) ->

    res.render 'index', domain: 'favicon.xydudu.com'
        

console.log 'ok, port 8080'
app.listen '8080'

sendIcon = ( $icon, $etagKey )->
    
    sended = true
    try
        header =
            'Content-Type': "image/png"
            'Content-Length': $icon.length
            'ETag': $etagKey
            'Cache-Control': 'public max-age=3600'

        @writeHead 200, header
        @write $icon, 'binary'
        @end()
    catch $err
        sended = false
    finally
        sended = false

saveFile = ( $key, $data )->

    fs.writeFile "#{__dirname}/public/cache/#{$key}.png", $data, 'binary', ( $err )->
        if $err
            console.log 'save have problem'
        else
            console.log 'It\'s saved!'

getFromAPI = ( $url, $fun )->
    request.get uri: "http://www.google.com/s2/favicons?domain=#{$url}", encoding: 'binary', ( $err, $res, $data )->
        if not $err then $fun $data
