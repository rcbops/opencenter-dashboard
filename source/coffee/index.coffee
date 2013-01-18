"use strict"

# Grab namespace
ntrapy = exports?.ntrapy ? @ntrapy

$ ->
  IndexModel = ->
    @getData = (url, cb) ->
      $.getJSON url, (data) ->
        cb data if cb?

    @mapData = (data, pin, map={}, wrap=true) ->
      data = [data] if wrap?
      ko.mapping.fromJS data, map, pin

    @getMappedData = (url, pin, map={}, wrap=true) =>
      @getData url, (data) => @mapData(data, pin, map, wrap)

    @config = {}
    @getData "/api/config/timeout", (data) =>
      @config.timeout = data

    @wsTemp = ko.observableArray()
    @wsItems = ko.computed =>
      @wsTemp()?[0]?.children ? []

    # TODO: Map from data source
    @siteNav = ko.observableArray [
      name: "Workspace"
      template: "indexTemplate"
    ,
      name: "Profile"
      template: "profileTemplate"
    ,
      name: "Settings"
      template: "settingsTemplate"
    ]

    mapping =
      children:
        key: (data) ->
          ko.utils.unwrapObservable data.id
        create: (options) ->
          createNode options
      node:
        key: (data) ->
          ko.utils.unwrapObservable data.id

    createNode = (options) =>
      @node = options.data
      console.log @node.name, @node?.facts?.backends
      ko.mapping.fromJS
        servers: (n for n in @node.children ? [] when "agent" in n.facts.backends)
        containers: (n for n in @node.children ? [] when "container" in n.facts.backends)
        actions: []
        status: ""
      , {}, ko.mapping.fromJS @node, mapping

    # Long-poller
    (poll = =>
      $.ajax
        url: "/roush/nodes/4?poll"
        success: (data) =>
          console.log "Zomg polled!"
          @mapData data, @wsTemp, mapping, wrap=false
        dataType: "json"
        complete: (xhr, txt) ->
          console.log "Txt: ", txt
          if txt is not "success"
            setTimeout poll, 1000
          else
            setTimeout poll, 0
        timeout: @config?.timeout?.long ? 30000
    )()

    @siteActive = ntrapy.selector (data) =>
      console.log "Triggered with: ", data
      switch data.name
        when "Workspace"
          @getMappedData "/roush/nodes/1/tree", @wsTemp, mapping, =>
            @wsItems [@wsTemp()[0].children]
    , @siteNav()[0] # Set to first by default

    # Template accessor that avoids data-loading race
    @getTemplate = ko.computed =>
      @siteActive()?.template ? {} # Needs .template?() if @siteNav is mapped

    @ # Return ourself

  popoverOptions =
    delay: 0
    trigger: "hover"
    animation: true
    placement: ntrapy.get_popover_placement

  ko.bindingHandlers.popper =
    init: (element, valueAccessor) ->
      $(element).popover popoverOptions

  ko.bindingHandlers.sortable.options =
    handle: ".btn"
    cancel: ""
    opacity: 0.35
    tolerance: "pointer"
    start: (event, ui) ->
      $(ui.item).find('button[data-bind*="popper"]')
        .popover("disable")
        .popover "hide"

  ntrapy.indexModel = new IndexModel()
  ko.applyBindings ntrapy.indexModel
