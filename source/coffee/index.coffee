"use strict"

# Grab namespace
ntrapy = exports?.ntrapy ? @ntrapy

$ ->
  IndexModel = ->
    @items = ko.observableArray()
  
    @statusColor = (status) ->
      switch status
        when "unprovisioned"
          return "#3A87AD"
        when "good"
          return "#468847"
        when "alert"
          return "#F89406"
        when "error"
          return "#B94A48"

    @statusLabel = (status) ->
      switch status
        when "unprovisioned"
          return "label-info"
        when "good"
          return "label-success"
        when "alert"
          return "label-warning"
        when "error"
          return "label-important"

    @statusButton = (status) ->
      switch status
        when "unprovisioned"
          return "btn-info"
        when "good"
          return "btn-success"
        when "alert"
          return "btn-warning"
        when "error"
          return "btn-danger"

    @sections = ko.observableArray [
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
#      ko.mapping.fromJS
#        nodes: (->
#          [n for n in node.children ? [] when "container" in n.facts.backends]
#        )()
#        nodes: []
#        actions: []
#      , {}, ko.mapping.fromJS node, mapping
      ko.mapping.fromJS node

    topmap =
      tree:
        key: (data) ->
          ko.utils.unwrapObservable data.id
        create: (options) ->
          ko.mapping.fromJS options.data, mapping

    @section = ntrapy.selector @sections, (data) =>
      console.log "Triggered with: ", data
      if data?.name is "Workspace"
##        $.getJSON "http://roush.propter.net:8080/nodes/1/tree", (data) =>
        $.getJSON "js/testdata.json", (data) =>
          ko.mapping.fromJS [data], topmap, @items
          console.log "Items: ", @items()
    , @sections()[0] # Activate first section by default

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
#  ko.applyBindings ntrapy.indexModel
