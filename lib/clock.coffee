Events  = require 'events'
Arduino = require 'johnny-five'

lpad = (number, length) ->
  str = '' + number
  str = '0' + str while str.length < length
  str

class Clock extends Events.EventEmitter
  TIME_CONTROL:
    FISHER:     'fisher'
    BRONSTEIN:  'bronstein'
    SIMPLE:     'simple'
    WORD:       'word'

  name:       null
  led:        null
  button:     null
  time:       null
  increment:  null
  running:    no
  
  constructor: (@name, @led, @button, @time, @increment = null, @timeControl = null) ->
    @led = new Arduino.Led @led if typeof @led is 'number'
    @button = new Arduino.Button @button if typeof @button is 'number'
    
    @button.on 'down', => @emit 'button.down' if @running
    @button.on 'hold', => @emit 'button.hold' # if @running
    
    @time *= 1000
    @increment *= 1000
    
    Object.defineProperties this,
      roundElapsedTime:
        get: -> Date.now() - @startDate
      
      timeInSeconds:
        get: -> Math.round @time / 1000
      
      incrementInSeconds:
        get: -> Math.round @increment / 1000
      
      timeFormatted:
        get: ->
          seconds = @timeInSeconds
          minutes = Math.floor seconds / 60
          
          if minutes isnt 0
            "#{if minutes < 0 then '-' else ''}#{Math.abs minutes}:#{lpad Math.abs(seconds % 60), 2}"
          else
            "#{if seconds < 0 then '-' else ''}0:#{Math.abs seconds}"
  
  toString: -> @name
  
  hasTimeControl: (type = null) ->
    @increment > 0 and @timeControl? and (!type? or @timeControl is type)
  
  start: ->
    if @hasTimeControl @TIME_CONTROL.FISHER
      @time += @increment
    
    @startDate = @lastUpdate = Date.now()
    @timer = setInterval (=> @update()), 1000
    @running = yes
    @led.on()
    
    @emit 'start', this
    true
  
  stop: ->
    @startDate = @lastUpdate = null
    clearInterval @timer
    @running = no
    @led.off()
    
    if @hasTimeControl @TIME_CONTROL.BRONSTEIN
      roundElapsedTime = @roundElapsedTime
      @time += if roundElapsedTime < increment
        roundElapsedTime
      else
        @increment
    
    @emit 'stop', this
    true
  
  update: ->
    elapsedTime = Date.now() - @lastUpdate
    @lastUpdate = Date.now()
    
    if @hasTimeControl @TIME_CONTROL.SIMPLE
      @time -= elapsedTime unless @roundElapsedTime < @increment
    else if @hasTimeControl @TIME_CONTROL.WORD
      timeBefore = @time
      timeAfter = @time -= elapsedTime
      if timeBefore > 0 and timeAfter <= 0
        @softTimeout()
      else
        @emit 'update', this
      return
    else @time -= elapsedTime
    
    unless @time <= 0
      @emit 'update', this
    else
      @timeout()
    true
  
  softTimeout: ->
    @emit 'timeout', this
    true
  
  timeout: ->
    @stop()
    @led.pulse 4000
    @emit 'timeout', this
    true

module.exports = Clock
