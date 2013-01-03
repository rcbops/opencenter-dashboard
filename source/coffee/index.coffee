"use strict"

# Grab namespace
ntrapy = exports?.ntrapy ? @ntrapy

$ ->
  IndexModel = ->
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
          createNode options.data

    createNode = (node) ->
      ko.mapping.fromJS
        nodes: ({n, actions: []} for n in node.children ? [] when "container" in n.facts.backends)
        actions: []
      , {}, ko.mapping.fromJS node, mapping

    @siteActive = ntrapy.selector (data) =>
      console.log "Triggered with: ", data
      switch data?.name
        when "Workspace"
          @getMappedData "http://roush.propter.net:8080/nodes/1/tree", @wsItems, mapping
    , @siteNav()[0] # Set to first by default

    @getMappedData = (url, pin, map={}, cb=null) ->
      $.getJSON url, (data) ->
        ko.mapping.fromJS [data], map, pin
        cb() if cb?

    # Template accessor that avoids data-loading race
    @getTemplate = ko.computed =>
      @siteActive().template ? {} # Needs .template?() if @siteNav is mapped

    # Preload data
    @getMappedData "http://roush.propter.net:8080/nodes/1/tree", @wsItems, mapping

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
