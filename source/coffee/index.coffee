"use strict"

# Grab namespace
ntrapy = exports?.ntrapy ? @ntrapy

$ ->
  IndexModel = ->
    @wsTemp = ko.observableArray([])
    @wsItems = ko.observableArray([])

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

    createNode = (options) =>
      @node = options.data
      console.log @node.name, @node?.facts?.backends
      ko.mapping.fromJS
        servers: (n for n in @node.children ? [] when "agent" in n.facts.backends)
        containers: (n for n in @node.children ? [] when "container" in n.facts.backends)
        actions: []
        status: ""
      , {}, ko.mapping.fromJS @node, mapping

    @getMappedData = (url, pin, map={}, cb=null) ->
      $.getJSON url, (data) ->
        ko.mapping.fromJS [data], map, pin
        cb() if cb?

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
