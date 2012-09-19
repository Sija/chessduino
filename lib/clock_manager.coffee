Events  = require 'events'
Arduino = require 'johnny-five'

class ClockManager extends Events.EventEmitter
  board:  null
  clocks: null
  
  constructor: (@board, @clocks...) ->
    throw new Error 'You must provide exactly two players' unless @clocks.length is 2
    for clock in @clocks
      do (clock) =>
        clock.on 'timeout', =>
          @board.warn 'Clock', "#{clock} timeouted"
          unless clock.hasTimeControl clock.TIME_CONTROL.WORD
            @otherClock(clock).stop()
          @emit 'timeout', clock
          true
        
        clock.on 'button.down', =>
          clock.stop()
          @otherClock(clock).start()
          @emit 'button.down', clock
          true
        
        clock.on 'button.hold', =>
          otherClock = @otherClock clock
          
          return unless otherClock.button.isDown
          return if clocks.indexOf(clock) % 2
          if clock.running or otherClock.running
            @stop()
          else
            @start()
          @emit 'button.hold', clock
          true
  
  otherClock: (clock) ->
    if clock is @clocks[0] then @clocks[1] else @clocks[0]
  
  start: ->
    @lastClock ||= @clocks[0]
    @lastClock.start()
    @emit 'start', @lastClock
    true
  
  stop: ->
    @lastClock = clock for clock in @clocks when clock.running
    clock.stop() for clock in @clocks
    @emit 'stop', @lastClock
    true

module.exports = ClockManager
