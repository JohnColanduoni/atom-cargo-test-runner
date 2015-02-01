fs     = require 'fs'
path   = require 'path'
util   = require 'util'
events = require 'events'
escape = require 'jsesc'
ansi   = require 'ansi-html-stream'
psTree = require 'ps-tree'
spawn  = require('child_process').spawn

clickablePaths = require './clickable-paths'

STATS_MATCHER = /(\d+)\s+(failed|passed|ignored|measured)/g

module.exports = class CargoWrapper extends events.EventEmitter

  constructor: (@context) ->
    @cargoPath = atom.config.get 'cargo-test-runner.cargoBinaryPath'
    @options = atom.config.get 'cargo-test-runner.options'
    @resetStatistics()

  stop: ->
    if @cargo?
      killTree(@cargo.pid)
      @cargo = null

  run: ->

    flags = ['test', getFileWithoutExtension(@context.test)]

    if @options
      Array::push.apply flags, @options.split ' '

    opts =
      cwd: @context.root
      env:
        PATH: path.dirname(@cargoPath)
        HOME: process.env.HOME

    @resetStatistics()
    @cargo = spawn @cargoPath, flags, opts

    if @textOnly
      @cargo.stdout.on 'data', (data) => @emit 'output', data.toString()
      @cargo.stderr.on 'data', (data) => @emit 'output', data.toString()
    else
      stream = ansi(chunked: false)
      @cargo.stdout.pipe stream
      @cargo.stderr.pipe stream
      stream.on 'data', (data) =>
        @parseStatistics data
        @emit 'output', clickablePaths.link data.toString()

    @cargo.on 'error', (err) =>
      @emit 'error', err

    @cargo.on 'exit', (code) =>
      if code is 0
        @emit 'success', @stats
      else
        @emit 'failure', @stats

  resetStatistics: ->
    @stats = []

  parseStatistics: (data) ->
    while matches = STATS_MATCHER.exec(data)
      @stats.push
        type: matches[2]
        count: parseInt matches[1]
      @emit 'updateSummary', @stats

getFileWithoutExtension = (path) ->
  path.substr(0, path.lastIndexOf('.'))


killTree = (pid, signal, callback) ->
  signal = signal or 'SIGKILL'
  callback = callback or (->)
  psTree pid, (err, children) ->
    childrenPid = children.map (p) -> p.PID
    [pid].concat(childrenPid).forEach (tpid) ->
      try
        process.kill tpid, signal
      catch ex
        console.log "Failed to #{signal} #{tpid}"
    callback()
