###
    
    Nodejs module to get favicon from a website
    @xydudu
    xydudu.com
    8.25/2011

###

url     = require 'url'
request = require 'request'

finish  = {}
htmlprocess = {}

isUrl = ( $url )->
    regexp = /((http|https):\/\/)?(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
    return regexp.test $url

iconFromUrl = ( $url, $key, $fun, $nonext=false )->
    
    console.log "try to find fav from #{$url}"

    if finish[ $key ] then return false

    favurl = _url = $url
    favurl = "http://#{ favurl }" if not /^http/.test favurl
    favurl = url.parse( favurl )
    _url = "#{ favurl.protocol }//#{ favurl.hostname }/favicon.ico"

    request.get uri: _url, encoding: 'binary', timeout: 5000, ( $err, $res, $body )->

        if not $err and 200 is $res.statusCode and isImage $res.headers
            console.log 'no err'
            return $fun { err: 0, data: $body }
        else
            console.log 'err'
            if htmlprocess[ $key ] then return $fun { err: 1, data: favurl.hostname }
            if not $nonext then iconFromHTML favurl.href, $key, $fun, favurl.hostname

        finish[ $key ] = true

    #if not $nonext then iconFromHTML favurl.href, $key, $fun

iconFromHTML = ( $pageurl, $key, $fun, $host )->

    if finish[ $key ] then return false
    request.get uri: $pageurl, timeout: 5000, ( $err, $res, $body )->

        if not $err and 200 is $res.statusCode
            console.log 'haha...find from html'

            pageurl = url.parse $pageurl

            link = $body.match /<link.*(shortcut )?icon.*\/>/g
            link = link[0] if link? and link[0]?

            reg = /href\=[\"|\'](.+\.ico)[\"|\']/gi
            reg.exec link
            ico = RegExp.$1

            console.log "ico is #{ico}"

            if /^http/.test ico
                ico = ico
            else
                ico = if /^\//.test ico then "#{ pageurl.protocol }//#{ pageurl.hostname }#{ ico }" else "#{ $pageurl }/#{ ico }"
            
            iconFromUrl ico, $key, $fun, htmlprocess[ $key ] = true
        else
            console.log 'find from htm err'
            $fun { err: 1, data: $host }



isImage = ( $header )->
    
    return /image/.test $header['content-type']


main = ( $url, $key, $fun )->
    
    console.log "URL:#{ $url }"

    fn = $fun || ( $result )->
        if not finish[ $key ]
            console.log $result
        finish[ $key ] = true

    ###
    t = setTimeout ()->
        fn 'timeout'
        clearTimeout t
    , 20000
    ###

    if isUrl $url
        iconFromUrl $url, $key, fn

if require.main is module
    main.apply this, process.argv.slice(2)

module.exports = main
