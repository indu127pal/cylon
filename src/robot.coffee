###
 * robot
 * cylonjs.com
 *
 * Copyright (c) 2013 The Hybrid Group
 * Licensed under the Apache 2.0 license.
###

'use strict';

require('./cylon')
Connection = require("./connection")
Device = require("./device")

module.exports = class Robot
  self = this

  constructor: (opts = {}) ->
    @robot = this
    @name = opts.name or @constructor.randomName()
    @master = opts.master
    @connections = {}
    @devices = {}
    @adaptors = {}
    @drivers = {}

    @registerAdaptor "./loopback", "loopback"

    @initConnections(opts.connection or opts.connections)
    @initDevices(opts.device or opts.devices)
    @work = opts.work or -> (Logger.info "No work yet")

  @randomName: ->
    "Robot #{ Math.floor(Math.random() * 100000) }"

  initConnections: (connections) =>
    Logger.info "Initializing connections..."
    return unless connections?
    connections = [].concat connections
    for connection in connections
      Logger.info "Initializing connection '#{ connection.name }'..."
      connection['robot'] = this
      @connections[connection.name] = new Connection(connection)

  initDevices: (devices) =>
    Logger.info "Initializing devices..."
    return unless devices?
    devices = [].concat devices
    for device in devices
      Logger.info "Initializing device '#{ device.name }'..."
      device['robot'] = this
      @devices[device.name] = new Device(device)

  start: =>
    @startConnections()
    @startDevices()
    @work.call(@robot, @robot)

  startConnections: =>
    Logger.info "Starting connections..."
    for n, connection of @connections
      Logger.info "Starting connection '#{ connection.name }'..."
      connection.connect()

  startDevices: =>
    Logger.info "Starting devices..."
    for n, device of @devices
      Logger.info "Starting device '#{ device.name }'..."
      this[device.name] = device

  requireAdaptor: (adaptorName, connection) ->
    if @robot.adaptors[adaptorName]?
      if typeof @robot.adaptors[adaptorName] is 'string'
        @robot.adaptors[adaptorName] = require(@robot.adaptors[adaptorName]).adaptor(name: adaptorName, connection: connection)
    else
      require("cylon-#{adaptorName}").register(this)
      @robot.adaptors[adaptorName] = require("cylon-#{adaptorName}").adaptor(name: adaptorName, connection: connection)

    return @robot.adaptors[adaptorName]

  registerAdaptor: (moduleName, adaptorName) ->
    return if @adaptors[adaptorName]?
    @adaptors[adaptorName] = moduleName

  requireDriver: (driverName, device) ->
    if @robot.drivers[driverName]?
      if typeof @robot.drivers[driverName] is 'string'
        @robot.drivers[driverName] = require(@robot.drivers[driverName]).driver(device: device)
    else
      require("cylon-#{driverName}").register(this)
      @robot.drivers[driverName] = require("cylon-#{driverName}").driver(device: device)

    return @robot.drivers[driverName]

  registerDriver: (moduleName, driverName) =>
    return if @drivers[driverName]?
    @drivers[driverName] = moduleName
