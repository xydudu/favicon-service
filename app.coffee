###
 get the favicon 
 
 TODO
    * deal with error
    * cache response

###
fs = require 'fs'
url     = require 'url'
express = require 'express'
#keygrip = require 'keygrip'
request = require 'request'
app     = express.createServer()
icon    = false
t       = null

app.use express.bodyParser()
app.use express.static(__dirname + '/public')
app.set 'views', __dirname + '/view'
app.set 'view engine', 'jade'

app.get /^\/fav\/(.+)/, ( req, res ) ->
    
    site = req.params[0]
    t = setTimeout ()->
        getDefaultIcon ( $icon )->
            sendIcon.call res, $icon, png
    , 5000

    if site and isSite site then findFav site, ( $icon )->
        sendIcon.call res, $icon

    else getDefaultIcon ( $icon )->
        sendIcon.call res, $icon, png

app.get "/", ( req, res ) ->
    
    res.render 'index', layout: false
        

app.listen '8888'

isSite = ( $url ) ->
    regexp = /((http|https):\/\/)?(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
    return regexp.test $url

getDefaultIcon = ( $fun )->

    return $fun( icon ) if icon is on

    defaultIcon = "#{__dirname}/public/favicons.png"
    
    fs.readFile defaultIcon, 'binary', ( $err, $data ) ->
        
        if not $err then $fun $data


    ###
    request uri: defaultIcon, encoding: 'binary', ( $err, $res, $body)->
        if not $err and $res.statusCode is 200
            $fun $body
    ###

sendIcon = ( $icon, $type='x-ico' ) ->

    clearTimeout t
    t = null
    @writeHead 200, 'Content-Type': "image/#{ $type }"
    @write $icon, 'binary'
    @end()

findFav = ( $url, $fun ) ->
   
    $url = "http://#{ $url }" if not /^http/.test $url
    site = url.parse( $url ).hostname

    if site then request uri: "http://#{ site }/favicon.ico", encoding: 'binary', ( $err, $res, $body )->

        ###
        if $res.statusCode is 404 then return getIconFromHtml site, ( $icon )->
            $fun $icon
        ###

        if $err or not $res.statusCode or $res.statusCode isnt 200
            getDefaultIcon ( $icon )->
                $fun $icon
        else
            $fun $body

#fin the favicon from the head in html
#有必要么？有必要么？
getIconFromHtml = ( $site, $fun ) ->
    # finish it later 
    $fun 'nothing'
    
