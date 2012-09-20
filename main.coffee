#!/usr/bin/env node

Arduino = require 'johnny-five'

Clock = require './lib/clock'
ClockManager = require './lib/clock_manager'

#
#
#
time_control_modes = Clock.TIME_CONTROL_MODES

program = require 'commander'

program
  .version('0.1.1')
  .option('-t, --time <amount>', 'minutes per side [15]', Number, 15)
  .option('-c, --time-control <type>', "type of time control (#{time_control_modes.join '|'}) [#{time_control_modes[0]}]",
    time_control_modes[0])
  .option('-i, --increment <amount>', 'increment in seconds [0]', Number, 0)
  .parse(process.argv)

#
#
#
board = new Arduino.Board

board.on 'ready', ->
  time = program.time * 60 # minutes -> seconds
  
  whitePlayerClock = new Clock 'White player', 13, 22, time, program.increment, program.timeControl
  blackPlayerClock = new Clock 'Black player', 5, 24, time, program.increment, program.timeControl
  
  manager = new ClockManager board, whitePlayerClock, blackPlayerClock
  manager.start()
  
  true

