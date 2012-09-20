Events  = require 'events'
Arduino = require 'johnny-five'

require './core_ext/array'

lpad = (number, length) ->
  str = '' + number
  str = '0' + str while str.length < length
  str

class Clock extends Events.EventEmitter
  @TIME_CONTROL:
    FISHER:     'fisher'
    BRONSTEIN:  'bronstein'
    SIMPLE:     'simple'
    WORD:       'word'
  
  @TIME_CONTROL_MODES:
    (value for key, value of @TIME_CONTROL)
  
  TIME_CONTROL: @TIME_CONTROL
  TIME_CONTROL_MODES: @TIME_CONTROL_MODES
  
  name:       null
  led:        null
  button:     null
  time:       null
  increment:  null
  running:    no
  timeouted:  no
  
  constructor: (@name, @led, @button, @time, @increment = null, @timeControl = null) ->
    throw new Error 'Led must be either pin number or object' unless typeof @led in ['number', 'object']
    throw new Error 'Button must be either pin number or object' unless typeof @button in ['number', 'object']
    
    throw new Error 'Time per side is not a number'  if isNaN @time
    throw new Error 'Increment time is not a number' if @increment? and isNaN @increment
    
    if @timeControl? and @timeControl not in @TIME_CONTROL_MODES
      throw new Error "Time control must be one of: #{@TIME_CONTROL_MODES.toSentence('or')}"
    
    @led = new Arduino.Led @led if typeof @led is 'number'
    @button = new Arduino.Button @button if typeof @button is 'number'
    
    @button.on 'down', => @emit 'button.down' if @running
    @button.on 'hold', => @emit 'button.hold' # if @running
    
    @time *= 1000
    @increment *= 1000 if @increment
    
    @originalTime = @time
    
    Object.defineProperties this,
      roundElapsedTime:
        get: -> Date.now() - @startDate
      
      timeInSeconds:
        get: -> Math.round @time / 1000
      
      incrementInSeconds:
        get: -> Math.round @increment / 1000 if @increment
      
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
    @led.stop()
    
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
    @timeouted = yes
    true
  
  timeout: ->
    @stop()
    @led.pulse 4000
    @emit 'timeout', this
    @timeouted = yes
    true
  
  reset: ->
    @stop()
    @time = @originalTime
    @timeouted = no
    true

module.exports = Clock
