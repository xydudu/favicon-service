###
    
    Nodejs module to get favicon from a website
    @xydudu
    xydudu.com
    8.25/2011

###

url     = require 'url'
request = require 'request'
finish  = false


isUrl = ( $url )->
    regexp = /((http|https):\/\/)?(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
    return regexp.test $url

iconFromUrl = ( $url, $fun, $nonext = false )->
    
    console.log "try to find fav from #{$url}"

    if finish then return false

    favurl = $url
    favurl = "http://#{ favurl }" if not /^http/.test favurl
    favurl = url.parse( favurl )

    request uri: "#{ favurl.protocol }//#{ favurl.hostname }/favicon.ico", encoding: 'binary', ( $err, $res, $body )->

        if 200 is $res.statusCode and isImage $res.headers
            $fun $body

    if not $nonext then iconFromHTML favurl.href, $fun

iconFromHTML = ( $pageurl, $fun )->

    if finish then return false
    request uri: $pageurl, ( $err, $res, $body )->

        if 200 is $res.statusCode

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
            
            iconFromUrl ico, $fun, true


isImage = ( $header )->
    
    return /image/.test $header['content-type']


main = ( $url, $fun )->
    
    console.log "URL:#{ $url }"

    fn = $fun || ( $result )->
        if not finish
            console.log $result
        finish = true

    t = setTimeout ()->
        fn 'false'
        clearTimeout t
    , 20000

    if isUrl $url
        iconFromUrl $url, fn

if require.main is module
    main.apply this, process.argv.slice(2)

module.exports = main
