## 找到一个网站的favicon并返回过来
# 
# 根据所得url 取得 favurl
#   根目录下的
#   查找页面 link(rel="icon") 的
#   默认的

sys     = require 'sys'
fs      = require 'fs'
url     = require 'url'
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

app.get /^\/fav\/(.+)/, ( req, res ) ->
    
    favurl = req.params[0]

    if isUrl favurl
        favurl = "http://#{ favurl }" if not /^http/.test favurl
        favurl = url.parse( favurl )
        
        #直接找根目录
        getIconFromUrl.call res, "#{ favurl.protocol }//#{ favurl.hostname }/favicon.ico", ( $icon )->
            sendIcon.call res, $icon

        #从HTML中找favicon地址并获取过来
        findIconFromHtml.call res, favurl.href, ( $url )->
            getIconFromUrl.call res, $url, ( $icon )->
                sendIcon.call res, $icon


    else getDefaultIcon ( $icon )->
        sendIcon.call res, $icon, 'png'


app.get "/", ( req, res ) ->
    
    res.render 'index', layout: false
        

app.listen '8080'

isUrl = ( $url )->
    regexp = /((http|https):\/\/)?(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
    return regexp.test $url

getDefaultIcon = ( $fun )->

    return $fun( icon ) if icon is on

    defaultIcon = "#{__dirname}/public/favicons.png"
    fs.readFile defaultIcon, 'binary', ( $err, $data ) ->
        if not $err then $fun $data

getIconFromUrl = ( $url, $fun )->

    self = @
    request uri: $url, encoding: 'binary', ( $err, $res, $body )->

        try
            if $err or 200 isnt $res.statusCode
                getDefaultIcon ( $icon )->
                    sendIcon.call self, $icon, 'png'
            else
                $fun $body

        catch $err
            getDefaultIcon ( $icon )->
                sendIcon.call self, $icon, 'png'

findIconFromHtml = ( $pageurl, $fun )->
    
    self = @
    request uri: $pageurl, ( $err, $res, $body )->
        if $err or 200 isnt $res.statusCode
            getDefaultIcon ( $icon )->
                sendIcon.call self $icon, 'png'
        else
            # <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
            pageurl = url.parse $pageurl
            link = $body.match /<link.*(shortcut )?icon.*\/>/g
            link = link[0] if link? and link[0]?
            reg = /href\=[\"|\'](.+\.ico)[\"|\']/gi
            reg.exec link
            ico = RegExp.$1
            if /^http/.test ico
                ico = ico
            else
                ico = if /^\//.test ico then "#{ pageurl.protocol }//#{ pageurl.hostname }#{ ico }" else "#{ $pageurl }/#{ ico }"
            
            getIconFromUrl.call self, ico, ( $icon )->
                sendIcon.call self, $icon


sendIcon = ( $icon, $type='x-ico' )->
    if sended then return
    sended = true
    try
        @writeHead 200, 'Content-Type': "image/#{ $type }"
        @write $icon, 'binary'
        @end()
    catch $err
        sended = false
    finally
        sended = false
        
