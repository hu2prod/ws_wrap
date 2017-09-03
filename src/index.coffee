require 'fy'
WebSocket = require 'ws'
require 'event_mixin'

class Websocket_wrap
  msg_uid  : 0
  
  websocket : null
  timeout_min : 100 # 100 ms
  timeout_max : 5*1000 # 5 sec
  # timeout_max : 5*60*1000 # 5 min
  timeout_mult: 1.5
  timeout     : 100
  url         : ''
  reconnect_timer : null
  queue       : []
  
  active_script_count : 0
  
  event_mixin @
  constructor : (@url)->
    event_mixin_constructor @
    @queue = []
    @timeout = @timeout_min
    @ws_init()
  
  delete : ()->
    return
  
  ws_reconnect : ()->
    return if @reconnect_timer
    @reconnect_timer = setTimeout ()=>
      @ws_init()
      return
    , @timeout
    return
  
  ws_init : ()->
    @reconnect_timer = null
    @websocket = new WebSocket @url
    @timeout = Math.min @timeout_max, Math.round @timeout*@timeout_mult
    @websocket.onopen   = ()=>
      @dispatch "reconnect"
      @timeout = @timeout_min
      q = @queue.clone()
      @queue.clear()
      for data in q
        @send data
      return
    @websocket.onerror  = (e)=>
      puts "Websocket error."
      perr e
      @ws_reconnect()
      return
    @websocket.onclose = ()=>
      puts "Websocket disconnect. Restarting in #{@timeout}"
      @ws_reconnect()
      return
    @websocket.onmessage = (message)=>
      data = JSON.parse message.data
      @dispatch "data", data
      return
    return
  
  send : (data)->
    if @websocket.readyState != @websocket.OPEN
      @queue.push data
    else
      @websocket.send JSON.stringify data
    return
  
  write : @prototype.send

module.exports = Websocket_wrap