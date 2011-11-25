###
    
    Nodejs module to get favicon from a website
    @xydudu
    xydudu.com
    8.25/2011
    9.05/2011 beta 2.0

###
keygrip = require 'keygrip'
url     = require 'url'
fs      = require 'fs'
request = require 'request'

INIT = 1
CACHEOVER = 2
REQUESTROOT = 3
REQUESTHTML = 4
REQUESTHTMLICO = 5

DEFAULTICON = 0

class favService

    constructor: ( @url, @req, @res, @defaultIcon, @savePath ) ->

        @log '开始了'
        @process = INIT
        if not isUrl @url
            return @sendDefault()

        if not /^http/.test @url then @url = "http://#{ @url }"

        [ @key, @rootUrl ] = @parseUrl @url
        @log "#{@key} ---- #{@url}"


        # Etag 
        if req.header('If-None-Match') is @key
            @log '304'
            @res.writeHead 304, 'Content-Type': 'image/png'
            @res.end()
            return
        
        # Cache File
        _ = @
        fs.readFile "#{ @savePath }/#{ @key }.png", "binary", ( $err, $data )->
            
            _.process = CACHEOVER
            if $err
                _.log.call _, '没找到缓存文件'
                return _.getIcon.call _, "#{ _.rootUrl }/favicon.ico", ( $json )->
                    if $json.err
                       _.log.call _, '寻找完全失败'
                       _.sendDefault.call _
                    else
                       _.log.call _, '要发送了。。。'
                       _.sendIcon.call _, $json.data
                       _.saveFile.call _, $json.data

            _.log '读取并使用缓存文件'
            _.sendIcon.call _, $data

    log: ( $msg )->
        
        console.log "[#{@url}][#{@process}]---#{$msg}"

    getIcon: ( $ico, $fun )->
        
        # Get icon from root/favicon.ico
        _ = @
        @log "在[#{ $ico }]中寻找"
        
        request.get uri: $ico, encoding: 'binary', timeout: 15000, ( $err, $res, $body )->
            
            _.process = REQUESTROOT if _.process isnt REQUESTHTML
            if not $err and 200 is $res.statusCode and _.isImage $res.headers

                _.log.call _, "[#{$ico}]已找到"
                return $fun { err: 0, data: $body }

            else
                _.log.call _, "[#{$ico}]没找到"
                _.findIconFromHtml.call _, _.url, ( $data )->
                    _.log.call _, '在html中寻找结束'
                    return $fun $data


    findIconFromHtml: ( $url, $fun )->

        if @process is REQUESTHTML then return false

        @log "开始在HTML上寻找"
        _ = @
        request.get uri: $url, timeout: 5000, ( $err, $res, $body )->
            _.process = REQUESTHTML
            if not $err and 200 is $res.statusCode

                _.log.call _, "完成HTML请求"

                pageurl = url.parse $url
                link = $body.match /<link.*(shortcut )?icon.*\/>/g
                link = link[0] if link? and link[0]?

                reg = /href\=[\"|\'](.+\.ico)[\"|\']/gi
                reg.exec link

                if RegExp.$1
                    ico = RegExp.$1
                    if /^http/.test ico
                        ico = ico
                    else
                        ico = if /^\//.test ico then "#{ pageurl.protocol }//#{ pageurl.hostname }#{ ico }" else "#{ $url }/#{ ico }"
                
                    _.log.call _, "ico是[#{ ico }]"
                    _.getIcon ico, $fun
                else
                    $fun { err: 1, data: $url }
            else
                _.log.call _, '请求HTML失败了'
                $fun { err: 1, data: $url }



    isImage: ( $header )->
        return /image/.test $header['content-type']

    # 获得特定key, hostname, protocol
    parseUrl: ( $url )->

        _url = $url
        _url = "http://#{ _url }" if not /^http/.test _url
        _url = url.parse( _url )

        return [
            keygrip( [ _url.hostname ] ).sign 'xydudu'
            "#{ _url.protocol }//#{ _url.hostname }/"
        ]
    
    sendDefault: ->
        if DEFAULTICON then return @sendIcon DEFAULTICON
        @log @defaultIcon
        _ = @
        fs.readFile @defaultIcon, "binary", ( $err, $data )->
            console.log $err
            if not $err
                DEFAULTICON = $data
                _.sendIcon.call _, $data
            else
                @res.send 'error', 500

    sendIcon: ( $icon )->
        
        @log 'send...'

        try
            header =
                'Content-Type': "image/x-icon"
                'Content-Length': $icon.length
                'ETag': @key
                'Cache-Control': 'public max-age=3600'

            @res.writeHead 200, header
            @res.write $icon, 'binary'
            @res.end()
        catch $err
            @res.send 'error', 500

    saveFile: ( $icon )->
        _ = @
        fs.writeFile "#{ @savePath }/#{ @key }.png", $icon, 'binary', ( $err )->
            if $err
                console.log $err
                _.log.call _, '保存cache文件时出问题了'
                _.res.send 'error', 500

            else
                console.log 'It\'s saved!'

        
# 检查是否是正确的URL
isUrl = ( $url )->
    regexp = /((http|https):\/\/)?(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
    return regexp.test $url

module.exports = favService
